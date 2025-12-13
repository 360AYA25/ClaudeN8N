-- Migration: Prompt-Schema Registry v1.0
-- Purpose: Centralized storage for AI Agent prompts, DB schema, RPC registry, service configs
-- Author: 5-Agent Orchestration System
-- Date: 2025-12-10

-- ============================================================
-- TABLE 1: prompts - Centralized AI Agent System Prompts
-- ============================================================

CREATE TABLE IF NOT EXISTS prompts (
  id TEXT PRIMARY KEY,              -- 'food_tracker_main_agent_v2'
  version INT DEFAULT 1,            -- Versioning for A/B testing
  locale TEXT DEFAULT 'ru',         -- Multi-language support
  role TEXT,                        -- 'main_agent', 'tool_agent', 'clarification'
  content TEXT NOT NULL,            -- Actual system prompt
  tags TEXT[],                      -- ['food', 'tracking', 'ai', 'telegram']
  active BOOLEAN DEFAULT TRUE,      -- Enable/disable without deletion
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by TEXT,                  -- 'architect_agent', 'manual', 'builder'
  notes TEXT                        -- Change rationale, A/B test notes
);

-- Indexes for prompts
CREATE INDEX IF NOT EXISTS idx_prompts_role ON prompts(role);
CREATE INDEX IF NOT EXISTS idx_prompts_active ON prompts(active);
CREATE INDEX IF NOT EXISTS idx_prompts_tags ON prompts USING GIN(tags);

-- Auto-versioning trigger for prompts
CREATE OR REPLACE FUNCTION update_prompts_version()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  IF NEW.content != OLD.content THEN
    NEW.version = OLD.version + 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prompts_version_trigger
BEFORE UPDATE ON prompts
FOR EACH ROW
EXECUTE FUNCTION update_prompts_version();

-- ============================================================
-- TABLE 2: schema_map - Current Supabase Schema Structure
-- ============================================================

CREATE TABLE IF NOT EXISTS schema_map (
  id SERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  column_name TEXT,
  data_type TEXT,
  is_nullable BOOLEAN,
  default_value TEXT,
  constraints TEXT[],              -- ['PRIMARY KEY', 'FOREIGN KEY users(id)']
  description TEXT,                -- Human-readable purpose
  last_verified_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unique constraint for schema_map
CREATE UNIQUE INDEX IF NOT EXISTS idx_schema_map_unique
ON schema_map(table_name, column_name);

-- Auto-refresh schema_map from information_schema
CREATE OR REPLACE FUNCTION refresh_schema_map()
RETURNS void AS $$
BEGIN
  TRUNCATE schema_map;

  INSERT INTO schema_map (table_name, column_name, data_type, is_nullable, default_value)
  SELECT
    c.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable::boolean,
    c.column_default
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
  ORDER BY c.table_name, c.ordinal_position;

  -- Update last_verified_at
  UPDATE schema_map SET last_verified_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TABLE 3: rpc_registry - Available RPC Functions
-- ============================================================

CREATE TABLE IF NOT EXISTS rpc_registry (
  id SERIAL PRIMARY KEY,
  function_name TEXT NOT NULL UNIQUE,
  description TEXT,                -- Human-readable purpose
  parameters JSONB,                -- {param1: {type: 'text', required: true}, ...}
  return_type TEXT,                -- 'TABLE', 'SETOF', 'JSON', etc.
  example_call TEXT,               -- "SELECT * FROM get_prompt('food_tracker_main', 2)"
  tags TEXT[],                     -- ['ai', 'prompts', 'user-facing']
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_verified_at TIMESTAMPTZ DEFAULT NOW()
);

-- Manual refresh for rpc_registry (auto-discovery in v1.1)
CREATE OR REPLACE FUNCTION refresh_rpc_registry()
RETURNS void AS $$
BEGIN
  -- Mark all as inactive first
  UPDATE rpc_registry SET active = FALSE;

  -- Reactivate functions that still exist in pg_proc
  UPDATE rpc_registry r
  SET active = TRUE, last_verified_at = NOW()
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname = r.function_name;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TABLE 4: service_registry - n8n Credentials & Service Configs
-- ============================================================

CREATE TABLE IF NOT EXISTS service_registry (
  id TEXT PRIMARY KEY,              -- 'openai_api_food_tracker'
  service_type TEXT,                -- 'openai', 'telegram', 'supabase', 'notion'
  credential_name TEXT,             -- Name in n8n credentials
  config JSONB,                     -- {model: 'gpt-4o', max_tokens: 4000}
  used_in_workflows TEXT[],         -- ['sw3Qs3Fe3JahEbbW', 'abc123']
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT                        -- Migration notes, config rationale
);

-- Index for service_registry
CREATE INDEX IF NOT EXISTS idx_service_registry_type ON service_registry(service_type);

-- ============================================================
-- TABLE 5: context_cache_versions - Track Cache Freshness
-- ============================================================

CREATE TABLE IF NOT EXISTS context_cache_versions (
  context_type TEXT PRIMARY KEY,   -- 'prompts', 'schema_map', 'rpc_registry', 'service_registry'
  version INT DEFAULT 1,
  last_updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by TEXT                   -- 'builder_agent', 'manual', 'auto_refresh'
);

-- Initial data for context_cache_versions
INSERT INTO context_cache_versions (context_type, version) VALUES
  ('prompts', 1),
  ('schema_map', 1),
  ('rpc_registry', 1),
  ('service_registry', 1)
ON CONFLICT (context_type) DO NOTHING;

-- Auto-increment version on any change
CREATE OR REPLACE FUNCTION increment_context_version(ctx_type TEXT)
RETURNS void AS $$
BEGIN
  UPDATE context_cache_versions
  SET version = version + 1,
      last_updated_at = NOW()
  WHERE context_type = ctx_type;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- RPC FUNCTIONS - API for Agents
-- ============================================================

-- get_prompt: Retrieve AI Agent system prompt
CREATE OR REPLACE FUNCTION get_prompt(
  prompt_id TEXT,
  prompt_version INT DEFAULT NULL
)
RETURNS TABLE(content TEXT, version INT, locale TEXT) AS $$
BEGIN
  IF prompt_version IS NULL THEN
    -- Get latest active version
    RETURN QUERY
    SELECT p.content, p.version, p.locale
    FROM prompts p
    WHERE p.id = prompt_id AND p.active = TRUE
    ORDER BY p.version DESC
    LIMIT 1;
  ELSE
    -- Get specific version
    RETURN QUERY
    SELECT p.content, p.version, p.locale
    FROM prompts p
    WHERE p.id = prompt_id AND p.version = prompt_version;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- list_prompts: List all AI Agent prompts with filters
CREATE OR REPLACE FUNCTION list_prompts(
  filter_role TEXT DEFAULT NULL,
  filter_locale TEXT DEFAULT NULL,
  active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
  id TEXT,
  version INT,
  role TEXT,
  locale TEXT,
  tags TEXT[],
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.version, p.role, p.locale, p.tags, p.updated_at
  FROM prompts p
  WHERE (filter_role IS NULL OR p.role = filter_role)
    AND (filter_locale IS NULL OR p.locale = filter_locale)
    AND (NOT active_only OR p.active = TRUE)
  ORDER BY p.updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- get_schema_map: Retrieve current DB schema
CREATE OR REPLACE FUNCTION get_schema_map(table_filter TEXT DEFAULT NULL)
RETURNS TABLE(
  table_name TEXT,
  column_name TEXT,
  data_type TEXT,
  is_nullable BOOLEAN,
  constraints TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT s.table_name, s.column_name, s.data_type, s.is_nullable, s.constraints
  FROM schema_map s
  WHERE (table_filter IS NULL OR s.table_name = table_filter)
  ORDER BY s.table_name, s.column_name;
END;
$$ LANGUAGE plpgsql;

-- get_available_rpcs: List available RPC functions
CREATE OR REPLACE FUNCTION get_available_rpcs(tag_filter TEXT DEFAULT NULL)
RETURNS TABLE(
  function_name TEXT,
  description TEXT,
  parameters JSONB,
  example_call TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT r.function_name, r.description, r.parameters, r.example_call
  FROM rpc_registry r
  WHERE r.active = TRUE
    AND (tag_filter IS NULL OR tag_filter = ANY(r.tags))
  ORDER BY r.function_name;
END;
$$ LANGUAGE plpgsql;

-- check_context_freshness: Check cache freshness status
CREATE OR REPLACE FUNCTION check_context_freshness()
RETURNS TABLE(
  context_type TEXT,
  current_version INT,
  last_updated_at TIMESTAMPTZ,
  freshness_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.context_type,
    c.version,
    c.last_updated_at,
    CASE
      WHEN c.last_updated_at > NOW() - INTERVAL '1 hour' THEN 'fresh'
      WHEN c.last_updated_at > NOW() - INTERVAL '24 hours' THEN 'stale'
      ELSE 'very_stale'
    END AS freshness_status
  FROM context_cache_versions c;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- INITIAL DATA MIGRATION
-- ============================================================

-- Migrate existing FoodTracker main agent prompt (example)
-- Note: Replace with actual prompt from workflow sw3Qs3Fe3JahEbbW
INSERT INTO prompts (id, version, locale, role, content, tags, created_by, notes) VALUES
(
  'food_tracker_main_agent_v2',
  1,
  'ru',
  'main_agent',
  'Ты — AI-агент FoodTracker для Telegram бота.

Твоя задача: помогать пользователю отслеживать питание, калории, макронутриенты (белки, жиры, углеводы) и водный баланс.

Функции, которые ты можешь использовать:
1. log_food_item - записать еду/напиток
2. log_water_intake - записать выпитую воду
3. get_daily_summary - получить дневной отчёт

Правила:
- Всегда отвечай на русском языке
- Используй эмодзи для калорий 🔥, белков 🥩, жиров 🧈, углеводов 🍞, воды 💧
- Формат чисел: ккал, г, мл (русские единицы!)
- Если пользователь запрашивает отчёт, вызови get_daily_summary
- ОБЯЗАТЕЛЬНО включай водный баланс в отчёт: "💧 Вода: XXX мл/день"

Примеры:
- "Записал! 🔥 450 ккал, 🥩 25г, 🧈 18г, 🍞 30г"
- "📊 Сегодня: 🔥 1850 ккал, 🥩 90г, 🧈 65г, 🍞 180г, 💧 Вода: 1200 мл"',
  ARRAY['food', 'tracking', 'ai', 'telegram'],
  'migration_001',
  'Initial migration from workflow sw3Qs3Fe3JahEbbW'
)
ON CONFLICT (id) DO NOTHING;

-- Populate rpc_registry with newly created functions
INSERT INTO rpc_registry (function_name, description, parameters, return_type, example_call, tags) VALUES
(
  'get_prompt',
  'Retrieve AI Agent system prompt by ID and optional version',
  '{"prompt_id": {"type": "text", "required": true}, "prompt_version": {"type": "int", "required": false}}'::jsonb,
  'TABLE(content TEXT, version INT, locale TEXT)',
  'SELECT * FROM get_prompt(''food_tracker_main_agent_v2'')',
  ARRAY['ai', 'prompts', 'user-facing']
),
(
  'list_prompts',
  'List all AI Agent prompts with optional filters',
  '{"filter_role": {"type": "text", "required": false}, "filter_locale": {"type": "text", "required": false}, "active_only": {"type": "boolean", "required": false}}'::jsonb,
  'TABLE(id TEXT, version INT, role TEXT, locale TEXT, tags TEXT[], updated_at TIMESTAMPTZ)',
  'SELECT * FROM list_prompts(filter_role := ''main_agent'')',
  ARRAY['ai', 'prompts', 'user-facing']
),
(
  'get_schema_map',
  'Retrieve current Supabase DB schema structure',
  '{"table_filter": {"type": "text", "required": false}}'::jsonb,
  'TABLE(table_name TEXT, column_name TEXT, data_type TEXT, is_nullable BOOLEAN, constraints TEXT[])',
  'SELECT * FROM get_schema_map(''food_logs'')',
  ARRAY['schema', 'developer-facing']
),
(
  'get_available_rpcs',
  'List all available RPC functions with optional tag filter',
  '{"tag_filter": {"type": "text", "required": false}}'::jsonb,
  'TABLE(function_name TEXT, description TEXT, parameters JSONB, example_call TEXT)',
  'SELECT * FROM get_available_rpcs(tag_filter := ''ai'')',
  ARRAY['rpc', 'developer-facing']
),
(
  'check_context_freshness',
  'Check freshness status of all context caches',
  '{}'::jsonb,
  'TABLE(context_type TEXT, current_version INT, last_updated_at TIMESTAMPTZ, freshness_status TEXT)',
  'SELECT * FROM check_context_freshness()',
  ARRAY['context', 'monitoring']
),
(
  'refresh_schema_map',
  'Refresh schema_map table from information_schema (post-migration hook)',
  '{}'::jsonb,
  'void',
  'SELECT refresh_schema_map()',
  ARRAY['schema', 'maintenance']
),
(
  'refresh_rpc_registry',
  'Refresh rpc_registry active status from pg_proc',
  '{}'::jsonb,
  'void',
  'SELECT refresh_rpc_registry()',
  ARRAY['rpc', 'maintenance']
),
(
  'increment_context_version',
  'Increment version for specified context type (internal)',
  '{"ctx_type": {"type": "text", "required": true}}'::jsonb,
  'void',
  'SELECT increment_context_version(''prompts'')',
  ARRAY['context', 'internal']
)
ON CONFLICT (function_name) DO NOTHING;

-- Initial schema_map refresh
SELECT refresh_schema_map();

-- Increment context versions after migration
SELECT increment_context_version('prompts');
SELECT increment_context_version('schema_map');
SELECT increment_context_version('rpc_registry');

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Test get_prompt
-- SELECT * FROM get_prompt('food_tracker_main_agent_v2');

-- Test list_prompts
-- SELECT * FROM list_prompts();

-- Test get_schema_map
-- SELECT * FROM get_schema_map('prompts');

-- Test get_available_rpcs
-- SELECT * FROM get_available_rpcs('ai');

-- Test check_context_freshness
-- SELECT * FROM check_context_freshness();

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================

-- Migration: 001_prompt_schema_registry.sql
-- Status: ✅ Complete
-- Tables Created: 5 (prompts, schema_map, rpc_registry, service_registry, context_cache_versions)
-- RPC Functions: 8 (get_prompt, list_prompts, get_schema_map, get_available_rpcs, check_context_freshness, refresh_schema_map, refresh_rpc_registry, increment_context_version)
-- Initial Data: FoodTracker main agent prompt migrated
-- Next Steps:
--   1. Apply migration via Supabase MCP: mcp__supabase__apply_migration
--   2. Test RPC calls from n8n AI Agent nodes
--   3. Update FoodTracker workflow to use get_prompt() instead of hardcoded prompt
--   4. Create pre/post-build hooks for auto-sync
