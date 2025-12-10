# ⚠️ Migration Conflicts Summary

**Date:** 2025-12-09
**Analysis:** Deep conflict analysis of 5-agent system vs MIGRATION-PLAN.md
**Full Report:** [AGENTS-HEALTH-REPORT.md](./AGENTS-HEALTH-REPORT.md)

---

## 🎯 Quick Summary

### Status: 🔴 **3 CRITICAL CONFLICTS FOUND**

**Bottom line:**
- ❌ Cannot migrate without fixes
- ⏱️ Fix time: 2-3 hours
- ✅ Rollback plan available
- 💰 Benefits: 82% token savings + portability

---

## 🔴 Critical Conflicts (Must Fix)

### 1. File Path References (30 min fix)

**Problem:**
- 53 hardcoded references to `memory/` paths
- All agents affected

**Impact:**
```bash
# Current:
memory/run_state_active.json      # 31 references
memory/agent_results/              # 20 references
memory/workflow_snapshots/         # 2 references

# After migration → FILE NOT FOUND errors!
```

**Fix:**
```bash
# Replace with:
${project_path}/.n8n/run_state.json
${project_path}/.n8n/agent_results/
${project_path}/.n8n/canonical.json
```

**Files to update:**
- researcher.md (6 paths)
- qa.md (11 paths)
- analyst.md (5 paths)
- builder.md (14 paths)
- shared/project-context-detection.md (2 paths)
- shared/run-state-append.md (11 paths)
- shared/validation-gates.md (4 paths)

---

### 2. Orchestrator SESSION START (20 min fix)

**Problem:**
- Missing project path detection logic
- Missing context freshness check
- Not passing paths to agents

**Impact:**
```javascript
// Current:
project_path = hardcoded_map[workflow_id]

// Migration needs:
project_path = from run_state OR user input
check context version vs workflow version
pass ${project_path} to all agents
```

**Fix:**
Add to `.claude/commands/orch.md`:
- Project path detection
- Context freshness check (compare versions)
- Pass PROJECT_PATH to agents in Task() prompt

---

### 3. Agent Reading Order (30 min fix)

**Problem:**
- Agents don't read SYSTEM-CONTEXT.md first
- All 5 agents affected

**Impact:**
```
Current order:
1. agent.md
2. run_state
3. indexes

Required order:
1. SYSTEM-CONTEXT.md  ← MISSING!
2. agent.md
3. run_state
4. indexes
```

**Fix:**
Update SESSION START in all 5 agents:
- architect.md
- researcher.md
- builder.md
- qa.md
- analyst.md

---

## 🟡 High Priority (Recommended)

### 4. Analyst ROLE 2 (45 min fix)

**Problem:**
- Analyst only does post-mortem (ROLE 1)
- Context Manager role (ROLE 2) not implemented

**Impact:**
- SYSTEM-CONTEXT.md won't auto-update
- Agents will read stale context
- Manual updates required (error-prone)

**Fix:**
Add to `.claude/agents/analyst.md`:
- ROLE 2: Context Manager
- Triggers: post-session, manual `/orch refresh context`
- Protocol: Extract → Generate → Update → Commit

---

## 🟢 No Conflicts (Ready)

### 5. Index-First Protocol ✅

**Status:** Compatible, no changes needed
**Benefit:** Even MORE savings (SYSTEM-CONTEXT replaces ARCHITECTURE.md)

### 6. Schema ✅

**Status:** Compatible, `project_path` already in schema
**Benefit:** No structural changes needed

### 7. Credentials ✅

**Status:** No discovery logic to update
**Benefit:** Credentials stay in .env files (secure)

---

## 📊 Impact Analysis

### Token Savings

**Before migration:**
- ARCHITECTURE.md: 10,000 tokens
- Indexes: 7,100 tokens
- **Total: 17,100 tokens per agent**

**After migration:**
- SYSTEM-CONTEXT.md: 1,800 tokens
- Indexes: 7,100 tokens
- **Total: 8,900 tokens per agent**

**Savings: 8,200 tokens (48%) per agent!**

### Portability

**Before:** Need 2 repos (ClaudeN8N/memory/ + project)
**After:** Single folder backup (project/.n8n/ + project/.context/)

### Organization

**Before:** All projects mixed in memory/
**After:** Each project isolated in .n8n/

---

## 🛠️ Fix Sequence

### Phase 1: Critical Fixes (80 min)

```bash
# 1. Update file paths (30 min)
cd .claude/agents
sed -i '' 's|memory/run_state_active.json|${project_path}/.n8n/run_state.json|g' *.md shared/*.md
sed -i '' 's|memory/agent_results/|${project_path}/.n8n/agent_results/|g' *.md shared/*.md
sed -i '' 's|memory/workflow_snapshots/|${project_path}/.n8n/|g' *.md shared/*.md

# 2. Update Orchestrator SESSION START (20 min)
# Add project detection, context check, path passing

# 3. Update Agent reading order (30 min)
# Add SYSTEM-CONTEXT.md reading to all 5 agents
```

### Phase 2: High Priority (45 min)

```bash
# 4. Implement Analyst ROLE 2 (45 min)
# Add Context Manager role to analyst.md
```

### Phase 3: Testing (60 min)

```bash
# 5. Run migration script
./scripts/migrate-to-distributed.sh /path/to/project workflow_id

# 6. Test FoodTracker
/orch test simple task

# 7. Verify auto-update
/orch finalize session
git diff .context/SYSTEM-CONTEXT.md
```

**Total time: 185 minutes (~3 hours)**

---

## 🚨 Risk Matrix

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| File not found | 🔴 CRITICAL | 100% | Fix Phase 1.1 |
| Session fails | 🔴 CRITICAL | 100% | Fix Phase 1.2 |
| Wrong read order | 🔴 CRITICAL | 100% | Fix Phase 1.3 |
| Stale context | 🟡 HIGH | 80% | Fix Phase 2.1 |
| Token increase | 🟢 LOW | 5% | Actually saves 48%! |

---

## ✅ Recommendation

### Option A: Fix Then Migrate ⭐ **RECOMMENDED**

**Pros:**
- ✅ Smooth migration (zero downtime)
- ✅ Token savings (48% per agent)
- ✅ Portability (single folder backup)
- ✅ Organization (isolated projects)

**Cons:**
- ⏱️ 3 hours implementation + testing

**Timeline:**
```
Day 1 (3 hours):
├── Phase 1: Critical fixes (80 min)
├── Phase 2: Analyst ROLE 2 (45 min)
└── Phase 3: Testing (60 min)
```

### Option B: Defer Migration

**Pros:**
- ✅ Current system stable
- ✅ No immediate rush

**Cons:**
- ❌ No token savings
- ❌ No portability
- ❌ Projects mixed in memory/

### Option C: Partial Migration (NOT RECOMMENDED)

**Pros:**
- ⏱️ Faster (80 min)

**Cons:**
- ⚠️ No auto-context updates
- ⚠️ Manual SYSTEM-CONTEXT maintenance
- ⚠️ Incomplete benefits

---

## 📋 Checklist Before Migration

**Pre-migration:**
- [ ] Review AGENTS-HEALTH-REPORT.md
- [ ] Understand all 4 conflicts
- [ ] Approve fix sequence
- [ ] Backup current system (`git commit`)

**During migration:**
- [ ] Execute Phase 1 fixes (80 min)
- [ ] Execute Phase 2 fixes (45 min)
- [ ] Run migration script
- [ ] Execute Phase 3 testing (60 min)

**Post-migration:**
- [ ] Verify all tests pass
- [ ] Check SYSTEM-CONTEXT.md generated
- [ ] Test agent reading order
- [ ] Test auto-update on session complete
- [ ] Commit changes

**Rollback plan:**
```bash
git revert <migration-commit>
# System back to working state in 1 minute
```

---

## 📞 Next Steps

1. **User reviews this summary**
2. **User decides:** Option A (fix + migrate), B (defer), or C (partial)
3. **If Option A:**
   - Start Phase 1: Update file paths
   - Continue Phase 2: Analyst ROLE 2
   - Complete Phase 3: Testing
4. **If Option B:**
   - Archive this analysis
   - Revisit when ready
5. **If Option C:**
   - Execute Phase 1 only
   - Accept manual context updates

---

## 📊 Conflict Score

**Total conflicts:** 7 analyzed
**Critical:** 3 🔴 (must fix)
**High:** 1 🟡 (recommended)
**No conflict:** 3 🟢 (ready)

**Readiness score:** 43% (3/7 ready without fixes)
**With fixes:** 100% (all conflicts resolved)

---

**Full analysis:** [AGENTS-HEALTH-REPORT.md](./AGENTS-HEALTH-REPORT.md)
**Migration plan:** [MIGRATION-PLAN.md](./MIGRATION-PLAN.md)
**Status:** ⏳ Awaiting user decision
