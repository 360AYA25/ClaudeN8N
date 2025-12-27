# Quick Start Checklist - Hybrid System

**Goal:** Setup local Qwen3-30B + cloud Claude Opus in 2 hours
**Savings:** ~70% cost reduction

---

## ⚡ ULTRA-FAST SETUP (Copy-Paste Commands)

### Phase 1: Install Ollama + Model (30 min)

```bash
# Install Ollama
brew install ollama

# Start server (Terminal 1)
ollama serve

# Download model (Terminal 2)
ollama pull qwen3-coder:30b-q4_K_M

# Test
ollama run qwen3-coder:30b-q4_K_M "Hello"
```

✅ **Checkpoint 1:** Model responds in ~1 second

---

### Phase 2: Install Router (15 min)

```bash
# Install
npm install -g claude-code-router

# Create config
mkdir -p ~/.claude-code-router
cat > ~/.claude-code-router/config.yaml <<'EOF'
models:
  - id: qwen3-30b-local
    endpoint: http://localhost:11434/v1
    type: openai
    default: false
    max_tokens: 8192

  - id: claude-opus
    endpoint: https://api.anthropic.com/v1
    type: anthropic
    api_key: ${ANTHROPIC_API_KEY}
    default: false
    model: claude-opus-4-5-20251101

  - id: claude-sonnet
    endpoint: https://api.anthropic.com/v1
    type: anthropic
    api_key: ${ANTHROPIC_API_KEY}
    default: true
    model: claude-sonnet-4-5-20251022

routing:
  default_model: claude-sonnet
  agent_routes:
    orchestrator: claude-sonnet
    architect: qwen3-30b-local
    researcher: qwen3-30b-local
    qa: qwen3-30b-local
    analyst: qwen3-30b-local
    builder: claude-opus

  model_mapping:
    "sonnet": qwen3-30b-local
    "haiku": qwen3-30b-local
    "opus": claude-opus

server:
  host: 127.0.0.1
  port: 3456
EOF

# Start router (Terminal 3)
claude-code-router start
```

✅ **Checkpoint 2:** Router started on port 3456

---

### Phase 3: Configure Claude Code (10 min)

```bash
# Set API key
echo 'export ANTHROPIC_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc

# Create settings
cat > ~/.claude/settings.json <<'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:3456/v1",
    "ANTHROPIC_AUTH_TOKEN": "${ANTHROPIC_API_KEY}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "qwen3-30b-local",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-5-20251101",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
EOF
```

✅ **Checkpoint 3:** Settings file created

---

### Phase 4: Test (10 min)

```bash
# Test router health
curl http://localhost:3456/health

# Start Claude Code (Terminal 4)
cd /Users/sergey/Projects/ClaudeN8N
claude

# In Claude Code, test:
# > Hello, which model are you?
# Expected: "I am Qwen3..."

# Test /orch
# > /orch --version
```

✅ **Checkpoint 4:** Everything works!

---

## 📊 Verification Matrix

| Component | Status | Command to Check |
|-----------|--------|-----------------|
| Ollama | [ ] | `curl http://localhost:11434/api/tags` |
| Model loaded | [ ] | `ollama list` |
| Router | [ ] | `curl http://localhost:3456/health` |
| Claude Code | [ ] | `claude --version` |
| n8n API | [ ] | `curl "$N8N_URL/api/v1/workflows" -H "X-N8N-API-KEY: $N8N_KEY"` |

---

## 🚀 Startup Script

Create `~/start-hybrid.sh`:

```bash
#!/bin/bash
echo "Starting hybrid system..."

# Terminal 1: Ollama
ollama serve > ~/.ollama/logs/ollama.log 2>&1 &

# Terminal 2: Router
sleep 3
claude-code-router start > ~/.claude-code-router/router.log 2>&1 &

echo "✅ All services started!"
echo "   Ollama:  http://localhost:11434"
echo "   Router:  http://localhost:3456"
echo ""
echo "Next: cd /Users/sergey/Projects/ClaudeN8N && claude"
```

```bash
chmod +x ~/start-hybrid.sh
```

---

## 🎯 Daily Use

```bash
# Start system
~/start-hybrid.sh

# Use Claude Code
cd /Users/sergey/Projects/ClaudeN8N
claude

# Your commands work as before!
/orch create workflow
```

---

## 🐛 Quick Troubleshooting

### Problem: "Connection refused"
```bash
# Check services
ps aux | grep ollama
ps aux | grep router

# Restart
pkill ollama && pkill claude-code-router
~/start-hybrid.sh
```

### Problem: "Model not found"
```bash
ollama pull qwen3-coder:30b-q4_K_M
```

### Problem: "High memory"
```bash
# Use lighter model
ollama pull qwen2.5-coder:14b-q4_K_M
# Update config to use 14B instead
```

---

## ✅ Success Criteria

- [ ] Ollama running (port 11434)
- [ ] Router running (port 3456)
- [ ] Model responds < 1 second
- [ ] Memory usage < 20GB
- [ ] /orch works
- [ ] Cost reduced ~70%

---

**Full documentation:** [HYBRID-SYSTEM-SETUP.md](HYBRID-SYSTEM-SETUP.md)
**Questions?** Check troubleshooting section in full guide

**Ready?** Start with Phase 1! 🚀
