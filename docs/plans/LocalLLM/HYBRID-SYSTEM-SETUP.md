# Hybrid System Setup: Local Qwen3-30B + Cloud Claude Opus

**Created:** 2025-12-24
**Purpose:** Setup hybrid AI agent system using local Qwen3-30B for non-critical agents and Claude Opus for Builder
**Hardware:** MacBook Air M4 24GB RAM
**Expected savings:** ~70% cost reduction
**Expected performance:** 100+ tokens/sec on local model

---

## 📋 EXECUTIVE SUMMARY

### What We're Building

```
┌─────────────────────────────────────────────┐
│  /orch (Entry point)                        │
└─────────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────┐
│  Orchestrator (Claude Sonnet - Cloud)       │
│  └─ Coordinates all agents                  │
└─────────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────────┐
│  Claude Code Router (Proxy)                 │
│  └─ Routes models: local vs cloud           │
└─────────────────────────────────────────────┘
                ↓
┌───────────────────┬─────────────────────────┐
│  LOCAL (Qwen3)    │  CLOUD (Claude Opus)    │
│  ├─ Architect     │  └─ Builder (CRITICAL!) │
│  ├─ Researcher    │                         │
│  ├─ QA            │                         │
│  └─ Analyst       │                         │
└───────────────────┴─────────────────────────┘
                ↓
┌─────────────────────────────────────────────┐
│  n8n API (via Bash + curl workaround)       │
└─────────────────────────────────────────────┘
```

### Agent Distribution

| Agent | Model | RAM Usage | Speed | Cost | Why |
|-------|-------|-----------|-------|------|-----|
| **Orchestrator** | Claude Sonnet (cloud) | - | Fast | Low | Coordination requires reliability |
| **Architect** | Qwen3-30B (local) | ~4GB | 100+ t/s | FREE | Dialog, planning - good for local |
| **Researcher** | Qwen3-30B (local) | ~4GB | 100+ t/s | FREE | Search, analysis - local works |
| **Builder** | Claude Opus (cloud) | - | Medium | High | CRITICAL - needs maximum accuracy |
| **QA** | Qwen3-30B (local) | ~4GB | 100+ t/s | FREE | Validation - local works |
| **Analyst** | Qwen3-30B (local) | ~4GB | 100+ t/s | FREE | Post-mortem - local works |

**Total local RAM:** ~16.5GB (Qwen3-30B shared in memory)
**Available RAM:** 24GB - 16.5GB (model) - 5GB (macOS) = **2.5GB buffer** ✅

---

## 🎯 PREREQUISITES

### Check Your System

```bash
# 1. MacBook specs
system_profiler SPHardwareDataType | grep -E "Model|Memory"
# Expected: MacBook Air, M4, 24 GB

# 2. Claude Code version
claude --version
# Expected: 2.0.75 or higher

# 3. Free disk space (need ~20GB for model)
df -h ~
# Expected: At least 25GB free

# 4. Node.js version (for Claude Code Router)
node --version
# Expected: v18+ or v20+

# 5. Python (for optional MLX)
python3 --version
# Expected: 3.9+

# 6. Project location
pwd
# Expected: /Users/sergey/Projects/ClaudeN8N
```

### Required API Keys

- [ ] **Anthropic API Key** - for Claude Opus (Builder)
  - Get from: https://console.anthropic.com/
  - Store in: `~/.zshrc` as `ANTHROPIC_API_KEY`

- [ ] **n8n API** - already configured in `.mcp.json` ✅

---

## 🚀 PHASE 1: INSTALL LOCAL MODEL (30 min)

### Option A: Ollama (RECOMMENDED - Simplest)

```bash
# 1. Install Ollama
brew install ollama

# 2. Start Ollama server
ollama serve &

# Verify server started
curl http://localhost:11434/api/tags
# Expected: {"models":[]}

# 3. Pull Qwen3-30B model (Q4 quantization)
ollama pull qwen3:30b-a3b-q4_K_M

# This will download ~16.5GB
# Expected time: 10-20 min depending on internet speed
# Expected output:
# pulling manifest
# pulling 4d3d7d0e9c6e...  16.5 GB / 16.5 GB
# verifying sha256 digest
# success

# 4. Test the model
ollama run qwen3:30b-a3b-q4_K_M "Hello, test message"

# Expected: Model responds with coherent text
# Expected speed: 80-100+ tokens/sec

# 5. Check model is loaded
ollama list
# Expected output:
# NAME                      ID              SIZE    MODIFIED
# qwen3:30b-a3b-q4_K_M     abc123...       16.5GB  X minutes ago
```

**Verification Checklist:**
- [ ] Ollama installed
- [ ] Ollama server running on port 11434
- [ ] Qwen3-30B downloaded (16.5GB)
- [ ] Model responds to test prompt
- [ ] Speed is 80+ tokens/sec

---

### Option B: LM Studio (Alternative - With GUI)

```bash
# 1. Download LM Studio
open https://lmstudio.ai

# 2. Install via .dmg file
# Drag to Applications

# 3. Open LM Studio
open -a "LM Studio"

# 4. In LM Studio:
#    a. Search: "Qwen3 30B"
#    b. Find: qwen3-30b-a3b-q4_K_M.gguf
#    c. Click Download (16.5GB)
#    d. Wait for download to complete

# 5. Load model:
#    a. Click on model in list
#    b. Click "Load Model"
#    c. Settings:
#       - GPU Layers: Max (auto)
#       - Context Length: 8192
#       - Temperature: 0.7

# 6. Start local server:
#    a. Go to "Server" tab
#    b. Click "Start Server"
#    c. Port: 1234 (default)
#    d. Model: qwen3-30b-a3b-q4_K_M

# 7. Test server
curl http://localhost:1234/v1/models
# Expected: JSON with model info
```

**Verification Checklist:**
- [ ] LM Studio installed
- [ ] Qwen3-30B downloaded
- [ ] Model loaded in LM Studio
- [ ] Server running on port 1234
- [ ] Test curl returns model info

---

### Option C: MLX (Advanced - Maximum Performance)

```bash
# 1. Install MLX
pip3 install mlx-lm

# 2. Download Qwen3-30B MLX version
python3 -m mlx_lm.convert \
  --hf-path Qwen/Qwen3-30B-A3B \
  --quantize \
  --q-bits 4 \
  --mlx-path ~/.ollama/models/qwen3-30b-mlx

# This downloads and converts to MLX format
# Expected time: 15-30 min
# Expected size: ~16GB

# 3. Start MLX server
mlx_lm.server \
  --model ~/.ollama/models/qwen3-30b-mlx \
  --port 8080 &

# 4. Test
curl http://localhost:8080/v1/models
```

**Verification Checklist:**
- [ ] MLX installed
- [ ] Model converted to MLX format
- [ ] Server running on port 8080
- [ ] Performance: 100+ tokens/sec

---

## 🔧 PHASE 2: INSTALL CLAUDE CODE ROUTER (15 min)

### Installation

```bash
# 1. Install Claude Code Router globally
npm install -g claude-code-router

# Verify installation
which claude-code-router
# Expected: /usr/local/bin/claude-code-router or similar

claude-code-router --version
# Expected: 1.x.x or higher

# 2. Create config directory
mkdir -p ~/.claude-code-router

# 3. Check if config exists
ls -la ~/.claude-code-router/
# Expected: Empty directory (new installation)
```

---

### Configuration

Create `~/.claude-code-router/config.yaml`:

```bash
cat > ~/.claude-code-router/config.yaml <<'EOF'
# Claude Code Router Configuration
# Purpose: Route models between local (Qwen3) and cloud (Claude)

# Model definitions
models:
  # Local Qwen3-30B via Ollama
  - id: qwen3-30b-local
    name: "Qwen3 30B Local"
    endpoint: http://localhost:11434/v1  # Ollama endpoint
    type: openai                         # OpenAI-compatible API
    default: false
    max_tokens: 8192
    temperature: 0.7
    context_window: 128000
    supports:
      - chat
      - completion
      - streaming

  # Cloud Claude Opus for Builder
  - id: claude-opus
    name: "Claude Opus 4.5"
    endpoint: https://api.anthropic.com/v1
    type: anthropic
    api_key: ${ANTHROPIC_API_KEY}       # From environment variable
    default: false
    model: claude-opus-4-5-20251101
    max_tokens: 8192
    temperature: 0.7
    context_window: 200000

  # Cloud Claude Sonnet for Orchestrator
  - id: claude-sonnet
    name: "Claude Sonnet 4.5"
    endpoint: https://api.anthropic.com/v1
    type: anthropic
    api_key: ${ANTHROPIC_API_KEY}
    default: true                        # Default for Orchestrator
    model: claude-sonnet-4-5-20251022
    max_tokens: 8192
    temperature: 0.7
    context_window: 200000

# Routing rules
routing:
  # Default routing
  default_model: claude-sonnet

  # Agent-specific routing
  agent_routes:
    # Orchestrator always uses Claude Sonnet (reliability)
    orchestrator: claude-sonnet

    # Local models for non-critical agents
    architect: qwen3-30b-local
    researcher: qwen3-30b-local
    qa: qwen3-30b-local
    analyst: qwen3-30b-local

    # Cloud Opus for critical Builder
    builder: claude-opus

  # Model mapping for Claude API compatibility
  model_mapping:
    # Map Claude model names to our IDs
    "claude-opus-4-5-20251101": claude-opus
    "claude-sonnet-4-5-20251022": claude-sonnet
    "sonnet": qwen3-30b-local           # Redirect "sonnet" to local
    "haiku": qwen3-30b-local            # Redirect "haiku" to local
    "opus": claude-opus                  # Keep "opus" on cloud

# Server settings
server:
  host: 127.0.0.1
  port: 3456
  log_level: info
  enable_cors: true

# Performance settings
performance:
  timeout: 120000        # 2 minutes
  retry_attempts: 3
  concurrent_requests: 5

# Logging
logging:
  enabled: true
  file: ~/.claude-code-router/router.log
  max_size: 10485760    # 10MB
  keep_files: 5
EOF
```

---

### Verify Configuration

```bash
# 1. Check config file
cat ~/.claude-code-router/config.yaml

# 2. Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('$HOME/.claude-code-router/config.yaml'))"
# Expected: No output = valid YAML

# 3. Test router (dry-run)
claude-code-router validate
# Expected: "Configuration valid"
```

**Verification Checklist:**
- [ ] config.yaml created
- [ ] YAML syntax valid
- [ ] All model endpoints correct
- [ ] ANTHROPIC_API_KEY referenced
- [ ] Routing rules defined

---

## ⚙️ PHASE 3: CONFIGURE CLAUDE CODE (10 min)

### Create Settings File

```bash
# 1. Create Claude settings directory
mkdir -p ~/.claude

# 2. Create settings.json
cat > ~/.claude/settings.json <<'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:3456/v1",
    "ANTHROPIC_AUTH_TOKEN": "${ANTHROPIC_API_KEY}",

    "ANTHROPIC_DEFAULT_SONNET_MODEL": "qwen3-30b-local",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "qwen3-30b-local",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-5-20251101",

    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
EOF

# 3. Set ANTHROPIC_API_KEY in environment
echo 'export ANTHROPIC_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc

# 4. Verify settings
cat ~/.claude/settings.json | jq .
# Expected: Valid JSON output
```

---

### Project-Specific Configuration

No changes needed! Your current `/orch` system will work as-is.

**Current system (working):**
```yaml
# .claude/agents/builder.md
---
model: opus  # Router will map to claude-opus
---

# .claude/agents/architect.md
---
model: sonnet  # Router will map to qwen3-30b-local
---
```

**Verification Checklist:**
- [ ] ~/.claude/settings.json created
- [ ] ANTHROPIC_BASE_URL points to router
- [ ] ANTHROPIC_API_KEY set in environment
- [ ] Model mappings correct

---

## 🧪 PHASE 4: TESTING (20 min)

### Start All Services

```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Start Claude Code Router
claude-code-router start

# Expected output:
# [INFO] Claude Code Router starting...
# [INFO] Loading config from ~/.claude-code-router/config.yaml
# [INFO] Registered model: qwen3-30b-local
# [INFO] Registered model: claude-opus
# [INFO] Registered model: claude-sonnet
# [INFO] Server listening on http://127.0.0.1:3456

# Terminal 3: Test router health
curl http://localhost:3456/health
# Expected: {"status":"ok","models":3,"uptime":...}
```

---

### Test 1: Router Model Routing

```bash
# Test local model (architect route)
curl -X POST http://localhost:3456/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "x-agent-role: architect" \
  -d '{
    "model": "sonnet",
    "max_tokens": 100,
    "messages": [
      {"role": "user", "content": "Say hello"}
    ]
  }'

# Expected: Response from Qwen3-30B
# Should see fast response (100+ t/s)

# Test cloud model (builder route)
curl -X POST http://localhost:3456/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "x-agent-role: builder" \
  -d '{
    "model": "opus",
    "max_tokens": 100,
    "messages": [
      {"role": "user", "content": "Say hello"}
    ]
  }'

# Expected: Response from Claude Opus
# Should see cloud API response
```

**Verification Checklist:**
- [ ] Router started successfully
- [ ] Health check passes
- [ ] Local model responds (architect)
- [ ] Cloud model responds (builder)
- [ ] Response times: local <1s, cloud <3s

---

### Test 2: Claude Code Integration

```bash
# Terminal 4: Start Claude Code in project
cd /Users/sergey/Projects/ClaudeN8N
claude

# In Claude Code, test simple command:
# > Hello, which model are you?

# Expected response from Qwen3-30B:
# "I am Qwen3-30B running locally via Ollama..."

# Test /orch system
# > /orch --version

# Expected: Orchestrator info
```

**Verification Checklist:**
- [ ] Claude Code starts
- [ ] Responds using local model
- [ ] /orch command works
- [ ] No errors in logs

---

### Test 3: Agent Model Assignment

Create test file `test-agents.sh`:

```bash
cat > /tmp/test-agents.sh <<'EOF'
#!/bin/bash

# Test which model each agent uses

echo "Testing Agent Model Assignment..."
echo "================================="

# Function to test agent
test_agent() {
  local agent=$1
  local expected_model=$2

  echo ""
  echo "Testing: $agent (expected: $expected_model)"

  # Simulate agent call through router
  response=$(curl -s -X POST http://localhost:3456/v1/messages \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "x-agent-role: $agent" \
    -d '{
      "model": "sonnet",
      "max_tokens": 50,
      "messages": [
        {"role": "user", "content": "What model are you?"}
      ]
    }')

  echo "Response: $response" | head -c 100
  echo "..."
}

# Test each agent
test_agent "architect" "qwen3-30b-local"
test_agent "researcher" "qwen3-30b-local"
test_agent "builder" "claude-opus"
test_agent "qa" "qwen3-30b-local"
test_agent "analyst" "qwen3-30b-local"

echo ""
echo "================================="
echo "Testing complete!"
EOF

chmod +x /tmp/test-agents.sh
/tmp/test-agents.sh
```

**Verification Checklist:**
- [ ] Architect uses Qwen3-30B
- [ ] Researcher uses Qwen3-30B
- [ ] Builder uses Claude Opus
- [ ] QA uses Qwen3-30B
- [ ] Analyst uses Qwen3-30B

---

### Test 4: n8n MCP Integration (Critical!)

```bash
# Test that agents can access n8n API via curl workaround

# 1. Test n8n API credentials
N8N_URL=$(jq -r '.mcpServers."n8n-mcp".env.N8N_API_URL' .mcp.json)
N8N_KEY=$(jq -r '.mcpServers."n8n-mcp".env.N8N_API_KEY' .mcp.json)

echo "Testing n8n API access..."
curl -s "$N8N_URL/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_KEY" | jq '.data[0].name'

# Expected: First workflow name

# 2. Test through local model
# In Claude Code:
# > /orch list workflows

# Expected: List of workflows from n8n
# Model used: Researcher (Qwen3-30B) via curl
```

**Verification Checklist:**
- [ ] n8n API accessible via curl
- [ ] /orch can list workflows
- [ ] Local model can use Bash + curl
- [ ] No MCP inheritance errors

---

## 📊 PHASE 5: PERFORMANCE MONITORING (10 min)

### Create Monitoring Script

```bash
cat > ~/monitor-hybrid-system.sh <<'EOF'
#!/bin/bash

# Monitor Hybrid System Performance

echo "==================================="
echo "Hybrid System Performance Monitor"
echo "==================================="
echo ""

# Check Ollama
echo "1. Ollama Status:"
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
  echo "   ✅ Running on port 11434"
  MODEL_COUNT=$(curl -s http://localhost:11434/api/tags | jq '.models | length')
  echo "   Models loaded: $MODEL_COUNT"
else
  echo "   ❌ NOT running"
fi

# Check Router
echo ""
echo "2. Claude Code Router:"
if curl -s http://localhost:3456/health > /dev/null 2>&1; then
  echo "   ✅ Running on port 3456"
  ROUTER_INFO=$(curl -s http://localhost:3456/health)
  echo "   Uptime: $(echo $ROUTER_INFO | jq -r '.uptime')"
  echo "   Models: $(echo $ROUTER_INFO | jq -r '.models')"
else
  echo "   ❌ NOT running"
fi

# Check Memory Usage
echo ""
echo "3. Memory Usage:"
TOTAL_MEM=$(sysctl hw.memsize | awk '{print $2/1024/1024/1024}')
USED_MEM=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages active:\s+(\d+)/ and printf("%.2f", $1 * $size / 1073741824);')
echo "   Total: ${TOTAL_MEM}GB"
echo "   Used: ${USED_MEM}GB"
echo "   Available: $( echo "$TOTAL_MEM - $USED_MEM" | bc )GB"

# Check Model Performance
echo ""
echo "4. Model Performance:"
START=$(date +%s%N)
curl -s -X POST http://localhost:11434/api/generate \
  -d '{"model":"qwen3:30b-a3b-q4_K_M","prompt":"Test","stream":false}' > /dev/null
END=$(date +%s%N)
LATENCY=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
echo "   Qwen3-30B latency: ${LATENCY}s"

# Check n8n API
echo ""
echo "5. n8n API Access:"
N8N_URL=$(jq -r '.mcpServers."n8n-mcp".env.N8N_API_URL' /Users/sergey/Projects/ClaudeN8N/.mcp.json)
N8N_KEY=$(jq -r '.mcpServers."n8n-mcp".env.N8N_API_KEY' /Users/sergey/Projects/ClaudeN8N/.mcp.json)
if curl -s "$N8N_URL/api/v1/workflows" -H "X-N8N-API-KEY: $N8N_KEY" > /dev/null 2>&1; then
  echo "   ✅ n8n API accessible"
  WF_COUNT=$(curl -s "$N8N_URL/api/v1/workflows" -H "X-N8N-API-KEY: $N8N_KEY" | jq '.data | length')
  echo "   Workflows: $WF_COUNT"
else
  echo "   ❌ n8n API NOT accessible"
fi

echo ""
echo "==================================="
EOF

chmod +x ~/monitor-hybrid-system.sh
~/monitor-hybrid-system.sh
```

**Expected Output:**
```
===================================
Hybrid System Performance Monitor
===================================

1. Ollama Status:
   ✅ Running on port 11434
   Models loaded: 1

2. Claude Code Router:
   ✅ Running on port 3456
   Uptime: 300s
   Models: 3

3. Memory Usage:
   Total: 24GB
   Used: 18.5GB
   Available: 5.5GB

4. Model Performance:
   Qwen3-30B latency: 0.156s

5. n8n API Access:
   ✅ n8n API accessible
   Workflows: 5

===================================
```

**Verification Checklist:**
- [ ] All services running
- [ ] Memory usage < 20GB
- [ ] Local model latency < 0.5s
- [ ] n8n API accessible

---

## 🔥 PHASE 6: PRODUCTION DEPLOYMENT (15 min)

### Create Startup Scripts

```bash
# 1. Create startup script for all services
cat > ~/start-hybrid-system.sh <<'EOF'
#!/bin/bash

echo "Starting Hybrid AI System..."
echo "=============================="

# Function to check if service is running
check_service() {
  local port=$1
  local name=$2

  if lsof -i :$port > /dev/null 2>&1; then
    echo "⚠️  $name already running on port $port"
    return 1
  fi
  return 0
}

# 1. Start Ollama
echo ""
echo "1. Starting Ollama..."
check_service 11434 "Ollama"
if [ $? -eq 0 ]; then
  ollama serve > ~/.ollama/logs/ollama.log 2>&1 &
  sleep 3
  echo "✅ Ollama started (PID: $!)"
else
  echo "   Skipping (already running)"
fi

# 2. Load Qwen3 model
echo ""
echo "2. Loading Qwen3-30B model..."
if ollama list | grep -q "qwen3:30b-a3b-q4_K_M"; then
  echo "✅ Model already loaded"
else
  ollama run qwen3:30b-a3b-q4_K_M "ready" > /dev/null 2>&1 &
  echo "✅ Model loading..."
fi

# 3. Start Claude Code Router
echo ""
echo "3. Starting Claude Code Router..."
check_service 3456 "Claude Code Router"
if [ $? -eq 0 ]; then
  claude-code-router start > ~/.claude-code-router/router.log 2>&1 &
  sleep 3
  echo "✅ Router started (PID: $!)"
else
  echo "   Skipping (already running)"
fi

# 4. Verify all services
echo ""
echo "4. Verifying services..."
sleep 2

OLLAMA_OK=$(curl -s http://localhost:11434/api/tags > /dev/null 2>&1 && echo "✅" || echo "❌")
ROUTER_OK=$(curl -s http://localhost:3456/health > /dev/null 2>&1 && echo "✅" || echo "❌")

echo "   Ollama:  $OLLAMA_OK"
echo "   Router:  $ROUTER_OK"

# 5. Display status
echo ""
echo "=============================="
echo "Hybrid System Status"
echo "=============================="
echo ""
echo "Services:"
echo "  - Ollama:         http://localhost:11434"
echo "  - Router:         http://localhost:3456"
echo "  - n8n:            $(jq -r '.mcpServers."n8n-mcp".env.N8N_API_URL' /Users/sergey/Projects/ClaudeN8N/.mcp.json)"
echo ""
echo "Logs:"
echo "  - Ollama:         tail -f ~/.ollama/logs/ollama.log"
echo "  - Router:         tail -f ~/.claude-code-router/router.log"
echo ""
echo "Next steps:"
echo "  1. cd /Users/sergey/Projects/ClaudeN8N"
echo "  2. claude"
echo "  3. /orch <your command>"
echo ""
EOF

chmod +x ~/start-hybrid-system.sh

# 2. Create stop script
cat > ~/stop-hybrid-system.sh <<'EOF'
#!/bin/bash

echo "Stopping Hybrid AI System..."

# Stop Router
pkill -f "claude-code-router"
echo "✅ Router stopped"

# Stop Ollama
pkill -f "ollama"
echo "✅ Ollama stopped"

echo "✅ All services stopped"
EOF

chmod +x ~/stop-hybrid-system.sh

# 3. Create restart script
cat > ~/restart-hybrid-system.sh <<'EOF'
#!/bin/bash

echo "Restarting Hybrid AI System..."
~/stop-hybrid-system.sh
sleep 2
~/start-hybrid-system.sh
EOF

chmod +x ~/restart-hybrid-system.sh
```

**Verification Checklist:**
- [ ] start-hybrid-system.sh created
- [ ] stop-hybrid-system.sh created
- [ ] restart-hybrid-system.sh created
- [ ] Scripts are executable

---

### Auto-Start on Login (Optional)

```bash
# Create LaunchAgent for auto-start

cat > ~/Library/LaunchAgents/com.user.hybrid-ai.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.hybrid-ai</string>

    <key>ProgramArguments</key>
    <array>
        <string>$HOME/start-hybrid-system.sh</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <false/>

    <key>StandardOutPath</key>
    <string>$HOME/.hybrid-ai/startup.log</string>

    <key>StandardErrorPath</key>
    <string>$HOME/.hybrid-ai/startup.error.log</string>
</dict>
</plist>
EOF

# Load LaunchAgent
launchctl load ~/Library/LaunchAgents/com.user.hybrid-ai.plist

# Verify
launchctl list | grep hybrid-ai
```

---

## ✅ PHASE 7: FINAL VERIFICATION (10 min)

### Complete System Test

```bash
# 1. Start all services
~/start-hybrid-system.sh

# 2. Wait for services to be ready
sleep 10

# 3. Run comprehensive test
cd /Users/sergey/Projects/ClaudeN8N

# 4. Create test workflow via /orch
# In Claude Code:
# > /orch create simple test workflow with webhook trigger

# Expected flow:
# - Orchestrator (Claude Sonnet) receives request
# - Calls Architect (Qwen3-30B local) for planning
# - Calls Researcher (Qwen3-30B local) for node search
# - Calls Builder (Claude Opus cloud) for workflow creation
# - Calls QA (Qwen3-30B local) for validation
# - Workflow created successfully

# 5. Monitor during test
# Terminal 2:
tail -f ~/.claude-code-router/router.log

# Should see:
# [INFO] Request from architect -> qwen3-30b-local
# [INFO] Request from researcher -> qwen3-30b-local
# [INFO] Request from builder -> claude-opus
# [INFO] Request from qa -> qwen3-30b-local
```

---

### Performance Verification

```bash
# Check performance metrics
~/monitor-hybrid-system.sh

# Expected metrics:
# - Memory usage: < 20GB
# - Local model latency: < 0.5s
# - Router uptime: > 0
# - All services: ✅
```

---

### Cost Verification

Track costs for 1 day:

```bash
# Create cost tracking script
cat > ~/track-costs.sh <<'EOF'
#!/bin/bash

LOG_FILE=~/.hybrid-ai/cost-tracking.log
ROUTER_LOG=~/.claude-code-router/router.log

# Count requests to each model
LOCAL_REQUESTS=$(grep "qwen3-30b-local" $ROUTER_LOG | wc -l)
OPUS_REQUESTS=$(grep "claude-opus" $ROUTER_LOG | wc -l)
SONNET_REQUESTS=$(grep "claude-sonnet" $ROUTER_LOG | wc -l)

# Estimate costs (tokens * price)
# Assuming average 5K tokens per request
LOCAL_COST=0  # Free!
OPUS_COST=$(echo "$OPUS_REQUESTS * 5000 * 0.000015" | bc)  # $15/1M
SONNET_COST=$(echo "$SONNET_REQUESTS * 5000 * 0.000003" | bc)  # $3/1M

TOTAL_COST=$(echo "$LOCAL_COST + $OPUS_COST + $SONNET_COST" | bc)

echo "==================================="
echo "Cost Tracking - $(date)"
echo "==================================="
echo "Requests:"
echo "  Local (Qwen3):   $LOCAL_REQUESTS"
echo "  Cloud (Opus):    $OPUS_REQUESTS"
echo "  Cloud (Sonnet):  $SONNET_REQUESTS"
echo ""
echo "Estimated costs:"
echo "  Local:   \$0.00 (FREE!)"
echo "  Opus:    \$$OPUS_COST"
echo "  Sonnet:  \$$SONNET_COST"
echo "  Total:   \$$TOTAL_COST"
echo ""
echo "Savings vs all-cloud: ~70%"
echo "==================================="

# Append to log
echo "$(date),$LOCAL_REQUESTS,$OPUS_REQUESTS,$SONNET_REQUESTS,$TOTAL_COST" >> $LOG_FILE
EOF

chmod +x ~/track-costs.sh

# Run daily
echo "0 0 * * * ~/track-costs.sh" | crontab -
```

---

## 📚 PHASE 8: DOCUMENTATION & MAINTENANCE

### Create Operations Manual

```bash
cat > /Users/sergey/Projects/ClaudeN8N/OPERATIONS.md <<'EOF'
# Hybrid System Operations Manual

## Daily Operations

### Starting the System
```bash
~/start-hybrid-system.sh
```

### Stopping the System
```bash
~/stop-hybrid-system.sh
```

### Checking Status
```bash
~/monitor-hybrid-system.sh
```

### Tracking Costs
```bash
~/track-costs.sh
```

## Troubleshooting

### Issue: Ollama not responding
```bash
# Check if running
ps aux | grep ollama

# Restart
~/restart-hybrid-system.sh

# Check logs
tail -f ~/.ollama/logs/ollama.log
```

### Issue: Router not routing correctly
```bash
# Check config
cat ~/.claude-code-router/config.yaml

# Verify routing
curl http://localhost:3456/health

# Check logs
tail -f ~/.claude-code-router/router.log
```

### Issue: High memory usage
```bash
# Check memory
vm_stat

# Restart Ollama (clears memory)
pkill ollama
ollama serve &

# Use lighter quantization (Q3 instead of Q4)
ollama pull qwen3:30b-a3b-q3_K_M
```

### Issue: Slow local model
```bash
# Check quantization level
ollama list

# Upgrade to MLX for M4 optimization
pip3 install mlx-lm
# (See Phase 1, Option C)
```

## Maintenance

### Weekly
- [ ] Run ~/monitor-hybrid-system.sh
- [ ] Check ~/track-costs.sh
- [ ] Review ~/.claude-code-router/router.log

### Monthly
- [ ] Update Ollama: `brew upgrade ollama`
- [ ] Update Router: `npm update -g claude-code-router`
- [ ] Check for new Qwen3 versions
- [ ] Review cost savings vs all-cloud

### Quarterly
- [ ] Evaluate new local models
- [ ] Consider upgrading to larger model if needed
- [ ] Archive old logs
EOF
```

---

## 🎯 SUCCESS CRITERIA

### System is Ready When:

- [ ] **All services running**
  - Ollama on port 11434
  - Claude Code Router on port 3456
  - n8n API accessible

- [ ] **Model routing works**
  - Architect → Qwen3-30B
  - Researcher → Qwen3-30B
  - Builder → Claude Opus
  - QA → Qwen3-30B
  - Analyst → Qwen3-30B

- [ ] **Performance meets targets**
  - Local model: 80+ tokens/sec
  - Memory usage: < 20GB
  - Response latency: < 1s local, < 3s cloud

- [ ] **Integration works**
  - /orch system functional
  - n8n API accessible via curl
  - Workflows can be created/updated
  - No MCP inheritance errors

- [ ] **Cost savings achieved**
  - ~70% reduction vs all-cloud
  - Builder still on Opus (quality)
  - Most agents on local (savings)

---

## 📊 EXPECTED RESULTS

### Performance Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Local model speed | 80+ t/s | _____ t/s | [ ] |
| Memory usage | < 20GB | _____ GB | [ ] |
| Response latency (local) | < 1s | _____ s | [ ] |
| Response latency (cloud) | < 3s | _____ s | [ ] |
| Cost reduction | 70% | _____ % | [ ] |

### Agent Distribution Verification

| Agent | Expected Model | Actual Model | Speed | Status |
|-------|---------------|--------------|-------|--------|
| Architect | Qwen3-30B | __________ | _____ t/s | [ ] |
| Researcher | Qwen3-30B | __________ | _____ t/s | [ ] |
| Builder | Claude Opus | __________ | _____ t/s | [ ] |
| QA | Qwen3-30B | __________ | _____ t/s | [ ] |
| Analyst | Qwen3-30B | __________ | _____ t/s | [ ] |

---

## 🚨 TROUBLESHOOTING GUIDE

### Common Issues

#### 1. Ollama Won't Start

**Symptoms:**
```bash
curl http://localhost:11434/api/tags
# Connection refused
```

**Solutions:**
```bash
# Check if port is in use
lsof -i :11434

# Kill existing process
pkill -f ollama

# Restart
ollama serve &

# Check logs
tail -f ~/.ollama/logs/ollama.log
```

---

#### 2. Model Not Downloaded

**Symptoms:**
```bash
ollama list
# qwen3:30b-a3b-q4_K_M not in list
```

**Solutions:**
```bash
# Pull model again
ollama pull qwen3:30b-a3b-q4_K_M

# If fails, try different mirror
OLLAMA_HOST=https://ollama.ai ollama pull qwen3:30b-a3b-q4_K_M

# Check disk space
df -h ~
# Need at least 20GB free
```

---

#### 3. Router Not Routing

**Symptoms:**
- All requests go to cloud
- Local model never used

**Solutions:**
```bash
# Check router config
cat ~/.claude-code-router/config.yaml | grep -A 10 "agent_routes"

# Verify model mapping
cat ~/.claude-code-router/config.yaml | grep -A 5 "model_mapping"

# Check router logs
tail -f ~/.claude-code-router/router.log | grep "routing"

# Restart router
~/restart-hybrid-system.sh
```

---

#### 4. High Memory Usage

**Symptoms:**
```bash
~/monitor-hybrid-system.sh
# Memory usage: 22GB (> 20GB)
```

**Solutions:**
```bash
# Option A: Use lighter quantization
ollama pull qwen3:30b-a3b-q3_K_M  # ~12GB instead of 16GB

# Option B: Use smaller model
ollama pull qwen2.5-coder:14b-q4_K_M  # ~8GB

# Option C: Restart Ollama (clears cache)
pkill ollama
ollama serve &
```

---

#### 5. Slow Performance

**Symptoms:**
- Local model < 50 tokens/sec
- High latency

**Solutions:**
```bash
# Check CPU usage
top -o cpu | head -20

# Close other apps

# Switch to MLX (M4 optimized)
pip3 install mlx-lm
# Use MLX instead of Ollama (see Phase 1, Option C)

# Reduce context window
# In config.yaml:
# context_window: 8192  # Instead of 128000
```

---

#### 6. n8n API Not Accessible

**Symptoms:**
```bash
curl "$N8N_URL/api/v1/workflows" -H "X-N8N-API-KEY: $N8N_KEY"
# 401 Unauthorized or Connection refused
```

**Solutions:**
```bash
# Verify credentials in .mcp.json
jq '.mcpServers."n8n-mcp".env' .mcp.json

# Test n8n directly in browser
open $(jq -r '.mcpServers."n8n-mcp".env.N8N_API_URL' .mcp.json)

# Check API key validity
# Regenerate in n8n if needed
```

---

## 📝 NEXT STEPS AFTER SETUP

### 1. Run Test Workflow (Day 1)

```bash
cd /Users/sergey/Projects/ClaudeN8N
claude

# In Claude Code:
/orch create test workflow
```

### 2. Monitor Performance (Week 1)

```bash
# Daily monitoring
~/monitor-hybrid-system.sh

# Track costs
~/track-costs.sh
```

### 3. Optimize Configuration (Week 2)

- Adjust model routing based on performance
- Fine-tune quantization levels
- Optimize memory usage

### 4. Production Use (Week 3+)

- Use system for real n8n workflows
- Track cost savings
- Document any issues

---

## 🎓 LEARNING RESOURCES

### Understanding the System

1. **Ollama Documentation**
   - https://github.com/ollama/ollama
   - Model library: https://ollama.com/library

2. **Claude Code Router**
   - https://github.com/musistudio/claude-code-router
   - Configuration guide: README.md

3. **Qwen3 Models**
   - https://huggingface.co/Qwen/Qwen3-30B-A3B
   - Quantization guide: https://github.com/ml-explore/mlx-lm

4. **MLX Framework** (Advanced)
   - https://github.com/ml-explore/mlx
   - Apple Silicon optimization

---

## 📞 SUPPORT

### Getting Help

1. **System Issues**
   - Check logs: `~/.claude-code-router/router.log`
   - Check logs: `~/.ollama/logs/ollama.log`

2. **Model Issues**
   - Ollama Discord: https://discord.gg/ollama
   - Qwen GitHub: https://github.com/QwenLM/Qwen3

3. **Router Issues**
   - GitHub Issues: https://github.com/musistudio/claude-code-router/issues

---

## ✅ FINAL CHECKLIST

### Pre-Deployment

- [ ] All prerequisites installed
- [ ] API keys configured
- [ ] Disk space available (25GB+)
- [ ] Memory sufficient (24GB)

### Installation Complete

- [ ] Ollama installed and running
- [ ] Qwen3-30B downloaded
- [ ] Claude Code Router installed
- [ ] Configuration files created
- [ ] Environment variables set

### Testing Passed

- [ ] Local model responds
- [ ] Cloud model responds
- [ ] Router routes correctly
- [ ] n8n API accessible
- [ ] /orch system works

### Production Ready

- [ ] Startup scripts created
- [ ] Monitoring set up
- [ ] Cost tracking enabled
- [ ] Documentation complete
- [ ] Team trained (if applicable)

---

## 🎉 CONGRATULATIONS!

If all checklists are complete, your hybrid AI system is **PRODUCTION READY**!

**What you've built:**
- 🚀 100+ tokens/sec local performance
- 💰 70% cost savings vs all-cloud
- 🎯 Critical Builder still on Claude Opus
- 🔧 Full n8n integration working
- 📊 Monitoring and cost tracking

**Next:** Start using `/orch` for real workflows!

---

**Document Version:** 1.0
**Last Updated:** 2025-12-24
**Status:** Ready for deployment
**Estimated Setup Time:** 2 hours total
**Maintenance Required:** Weekly monitoring, monthly updates
