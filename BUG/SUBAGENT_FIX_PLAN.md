# Agent System Deep Analysis & Fix Plan

> **Initial analysis:** 2025-12-03
> **Workaround status:** IMPLEMENTED (Issue #7296)
> **Deep analysis:** 2025-12-03
> **Current status:** Cleanup fixes pending user approval

---

## Executive Summary

Workaround for Issue #7296 has been **successfully implemented and tested**:
- Custom agents now work via `general-purpose` with role injection
- Test workflow `P8waWz4QAqeFuVRq` created successfully via MCP

Deep analysis found **12 documentation issues** requiring cleanup:
- **Critical:** 0 | **High:** 4 | **Medium:** 6 | **Low:** 2

---

## Part 1: Workaround Implementation (COMPLETE)

### Problem
Custom agents (builder, qa, etc.) cannot execute tools (MCP, Bash, Read, Write).

### Solution Implemented
Use `general-purpose` built-in agent with role in prompt:

```javascript
// OLD (broken):
Task({ subagent_type: "builder", prompt: "..." })

// NEW (works):
Task({
  subagent_type: "general-purpose",
  model: "opus",  // for builder
  prompt: `## ROLE: Builder Agent
Read: .claude/agents/builder.md

## TASK: ...`
})
```

### Files Updated
- `.claude/commands/orch.md` - All Task calls updated
- `.claude/CLAUDE.md` - Examples updated

### Verification
- Test workflow created: `P8waWz4QAqeFuVRq`
- MCP tools work correctly
- Merged to main branch

---

## Part 2: Deep Analysis Findings

### Issue 1: Obsolete File Reference (HIGH)
**File:** `qa.md` line 109
**Problem:** References `docs/MCP-BUG-RESTORE.md` which doesn't exist
**Actual location:** `BUG/archive/MCP-BUG-RESTORE_OBSOLETE.md`
**Fix:** Remove reference

### Issue 2: L-075 Outdated Message (HIGH)
**Files:** `builder.md:49`, `qa.md`, `researcher.md`
**Problem:** L-075 says "Bug #10668 not fixed" but bug IS fixed
**Fix:** Update to reflect current status

### Issue 3: Contradictory MCP Status (HIGH)
**File:** `qa.md`
**Problem:**
- Line 56-64: "All MCP operations working!"
- Line 967: "ACTIVATION via curl (MCP broken!)"
**Fix:** Remove outdated "MCP broken" comments

### Issue 4: Orchestrator "PURE ROUTER" vs L-073 (HIGH)
**File:** `orch.md`
**Problem:**
- Line 27-28: "ORCHESTRATOR = PURE ROUTER (NO TOOLS!)"
- Line 341-353: Shows Orchestrator calling MCP tools
**Clarification:** L-073 verification is *delegated to QA*, not direct Orchestrator calls
**Fix:** Add clarifying comment

### Issue 5: Agent Frontmatter Tools (MEDIUM)
**Files:** All agent .md files
**Problem:** Frontmatter `tools:` lists are ignored with workaround
**Impact:** None (purely documentation)
**Fix:** Add note explaining frontmatter is informational only

### Issue 6: Obsolete Bug References (MEDIUM)
**File:** `researcher.md` line 67
**Problem:** "not affected by Zod bug #444, #447" - bugs are fixed
**Fix:** Update note

### Issue 7: Duplicated L-075 Protocol (MEDIUM)
**Files:** `builder.md`, `qa.md`, `researcher.md`
**Problem:** Same ~100 lines repeated in each file
**Fix:** Consolidate to `shared/L-075-anti-hallucination.md`
**Savings:** ~600 tokens per session

### Issue 8: Duplicated Project Context Detection (MEDIUM)
**Files:** `builder.md`, `qa.md`, `researcher.md`
**Problem:** Same ~20 lines repeated
**Fix:** Move to `shared/project-context-detection.md`

### Issue 9: L-067 References (MEDIUM)
**Files:** All agents
**Status:** Correct - file exists at `shared/L-067-smart-mode-selection.md`
**Action:** No change needed

### Issue 10: Deprecated curl Comments (MEDIUM)
**File:** `qa.md` lines 966-982
**Problem:** Comments say "MCP broken!" but MCP works
**Fix:** Update to "curl as backup option"

### Issue 11: This File Location (LOW)
**File:** `SUBAGENT_FIX_PLAN.md`
**Status:** Correctly in `BUG/` folder now

### Issue 12: Test Workflow (LOW)
**ID:** `P8waWz4QAqeFuVRq`
**Problem:** Test workflow left in n8n
**Fix:** Delete or tag as test

---

## Fix Plan

### Phase 1: Critical Documentation (5 mins)

| # | File | Line | Change |
|---|------|------|--------|
| 1 | qa.md | 109 | Remove `docs/MCP-BUG-RESTORE.md` reference |
| 2 | builder.md | 49 | Update L-075: "MCP tools working (Bug #10668 fixed)" |
| 3 | qa.md | ~27 | Update L-075 similarly |
| 4 | researcher.md | ~27 | Update L-075 similarly |
| 5 | qa.md | 967 | Change "MCP broken!" to "curl as backup" |

### Phase 2: Contradiction Resolution (5 mins)

| # | File | Change |
|---|------|--------|
| 6 | orch.md L-073 | Add comment: "Verification delegated to QA agent" |
| 7 | researcher.md | Update Zod bug note |

### Phase 3: Code Deduplication (Optional - 15 mins)

| # | Action |
|---|--------|
| 8 | Create `shared/L-075-anti-hallucination.md` |
| 9 | Create `shared/project-context-detection.md` |
| 10 | Replace inline code with references |

### Phase 4: Cleanup (2 mins)

| # | Action |
|---|--------|
| 11 | Delete test workflow `P8waWz4QAqeFuVRq` |
| 12 | Add frontmatter note about workaround |

---

## User Decision Required

**Options:**

1. **Quick fix (Phase 1-2):** Fix critical issues only
   - Time: ~10 mins
   - Removes broken references and contradictions

2. **Full cleanup (All phases):** Complete cleanup
   - Time: ~25 mins
   - Includes code deduplication

3. **Skip:** Leave as-is
   - System works, docs are just messy

---

## Original Analysis (for reference)

### What Was Broken
Custom agents couldn't call tools - they hallucinated results.

### What We Fixed
Changed Task calls to use `general-purpose` with role in prompt.

### What's Preserved
- 5-agent architecture (architect, researcher, builder, qa, analyst)
- Specialized instructions in .md files
- run_state.json shared state
- All learnings and patterns
- Snapshot system
- QA loops and escalation
- Context isolation (each agent = separate process)

### What Changed
- `subagent_type: "builder"` -> `subagent_type: "general-purpose"` + role
- Agent reads its own .md file
- Model selection via `model: "opus"` parameter
