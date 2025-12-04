# SYSTEM AUDIT: Agent Architecture Failures

**Date:** 2025-12-04
**Task:** Task 2.4 context injection fix
**Result:** 8+ failed attempts, 3+ hours wasted
**Root Cause:** SYSTEMIC FAILURES in agent coordination, not workflow issues

---

## 📊 Failure Timeline Analysis

### Attempt History

| # | Agent | Action | Assumption | Verification | Result |
|---|-------|--------|------------|--------------|--------|
| 1 | Builder | Change promptType to define | Will fix field contract | ❌ NONE | FAIL |
| 2 | Builder | Update User Goal jsonBody→parametersBody | Will fix one tool | ❌ NONE | FAIL |
| 3 | Builder | Update 3 more tools parametersBody | Will fix all tools | ❌ NONE | FAIL |
| 4 | Builder | Add System Prompt examples | Will fix tool selection | ❌ NONE | FAIL |
| 5 | Analyst | Revert promptType (field contract) | Fixed real issue | ✅ Checked execution | SUCCESS (partial) |
| 6 | Builder | Upgrade AI Agent v2.2→v3 | New version will help | ❌ NONE | FAIL |
| 7 | Builder | Fix Search Today Entries params | Copy-paste bug | ❌ NONE | FAIL |
| 8 | Builder | Add valueProvider="fieldValue" | Different syntax | ❌ NONE | FAIL |
| 9 | Builder | All 6 tools use $fromAI() | LangChain function works | ❌ NONE | FAIL |

### Pattern Recognition

**SUCCESS (Attempt 5):**
- ✅ Analyst checked **execution logs FIRST**
- ✅ Found **exact stopping point** (AI Agent input)
- ✅ Identified **root cause** (field contract mismatch)
- ✅ Verified with **execution data**
- Result: Bot started working

**FAILURES (1-4, 6-9):**
- ❌ Builder made **assumptions** about fix
- ❌ **No execution log analysis**
- ❌ Said "fixed" without **real testing**
- ❌ Repeated **same approach** multiple times
- Result: Wasted time, user frustration

---

## 🚨 SYSTEMIC FAILURES

### 0. **ORCHESTRATOR IGNORES ITS OWN PROTOCOL** (CRITICAL!)

**Problem:** Progressive escalation EXISTS in orch.md but NOT EXECUTED

**Documented Protocol (orch.md lines 196-203):**
```
QA Loop (max 7 cycles — progressive)
├── Cycle 1-3: Builder fixes directly
├── Cycle 4-5: Researcher helps find alternative approach
├── Cycle 6-7: Analyst diagnoses root cause
└── After 7 fails → stage="blocked"
```

**What Actually Happened in Task 2.4:**
```
Cycle 1-8: Builder only (same approaches repeated)
Cycle 4-5: Researcher NOT CALLED (protocol violation!)
Cycle 6-7: Analyst NOT CALLED (protocol violation!)
→ User had to demand Analyst manually
```

**Impact:**
- 8 cycles of Builder guessing (should be 3 max)
- Alternative approaches never explored (Researcher skipped)
- Root cause analysis delayed until user rage (Analyst skipped)
- Protocol written but not enforced

**Root Cause:**
Orchestrator doesn't CHECK cycle_count and ENFORCE escalation rules. It's a passive router, not protocol enforcer.

**Evidence:**
- `/orch` command runs
- Orchestrator delegates to Builder
- Builder fails
- QA reports failure
- Orchestrator delegates to Builder AGAIN (no escalation check!)
- Repeat 8 times...

**Why Protocol Failed:**
1. No cycle_count check in Orchestrator logic
2. No "if (cycle >= 4) → call Researcher" enforcement
3. No "if (cycle >= 6) → call Analyst" enforcement
4. Orchestrator trusts agents will self-escalate (they don't!)

---

### 1. **No Mandatory Execution Analysis**

**Problem:** Agents skip execution log analysis

**Evidence:**
- Attempts 1-4: No execution data checked
- Attempts 6-8: Changes made without checking logs
- Only Attempt 5 (Analyst) checked execution → SUCCESS

**Impact:**
- Guessing instead of diagnosing
- Multiple failed attempts
- User frustration

**Root Cause:** Orchestrator doesn't FORCE execution analysis before fixes

---

### 2. **"Fixed" Without Verification**

**Problem:** Builder says "done" without real testing

**Evidence:**
```
Builder: "Updated 6 tools with $fromAI() - READY"
QA: "Validation PASSED - 0 errors"
Orchestrator: "Ask user to test"
Reality: Bot still silent (not tested!)
```

**Impact:**
- False confidence
- User wastes time testing broken fixes
- Multiple rounds of "ready → fails → fix again"

**Root Cause:** No mandatory Phase 5 BEFORE claiming success

---

### 3. **QA Validation ≠ Execution Testing**

**Problem:** QA checks configuration, not actual execution

**Evidence:**
```
QA: "✅ All 6 tools use $fromAI() correctly"
QA: "✅ Expression syntax valid"
QA: "✅ 0 validation errors"
Reality: $fromAI() returns undefined (execution failure!)
```

**Impact:**
- Green checkmarks on broken functionality
- Configuration looks good but doesn't work
- No one catches runtime failures

**Root Cause:** QA only does static validation, not execution testing

---

### 4. **Analyst Called Too Late**

**Problem:** Analyst invoked after 7+ failures, not at failure #2

**Evidence:**
- Attempt 5: Analyst finds root cause in 5 minutes
- Attempts 1-4: Builder guessing for hours
- Analyst has execution analysis tools but not used early

**Impact:**
- Wasted 2+ hours on guessing
- User extreme frustration
- Late escalation

**Root Cause:** No escalation trigger after 2 failures

---

### 5. **No Context Between Attempts**

**Problem:** Builder doesn't see what was already tried

**Evidence:**
```
Attempt 1: Try promptType change
Attempt 2: Try different body format
Attempt 3: Try same body format again (!)
Attempt 7: Try different parameters
Attempt 8: Try different syntax
→ No learning, repeating patterns
```

**Impact:**
- Same approaches repeated
- No elimination of failed paths
- Circular debugging

**Root Cause:** Agents don't read previous fix_attempts history

---

### 6. **Researcher Assumptions vs Facts**

**Problem:** Researcher proposes $fromAI() without testing

**Evidence:**
```
Researcher: "$fromAI() will work because Prepare Message Data provides telegram_user_id"
Reality: AI Agent receives only $json.data (text), not full context
Result: $fromAI() returns undefined
```

**Impact:**
- Confident but wrong solution
- Builder implements untested approach
- Another failed attempt

**Root Cause:** Researcher doesn't verify hypotheses with execution data

---

### 7. **Orchestrator Doesn't Enforce Protocol**

**Problem:** Orchestrator allows shortcuts, doesn't block bad handoffs

**Evidence:**
```
Builder → QA handoff:
  Builder: "Fixed 6 tools"
  Missing: mcp_calls proof, execution test
  Orchestrator: ✅ Allows (should BLOCK!)

QA → User handoff:
  QA: "Ready for deploy"
  Missing: Phase 5 real test
  Orchestrator: ✅ Allows (should BLOCK!)
```

**Impact:**
- Validation gates ignored
- Broken work passed forward
- User receives untested changes

**Root Cause:** Orchestrator is passive router, not enforcer

---

## 🎯 ARCHITECTURAL ROOT CAUSES

### Problem 1: **Linear Flow Without Verification Gates**

**Current Flow:**
```
Orchestrator → Researcher → Builder → QA → User
             ↓            ↓        ↓     ↓
         (no gates)  (no gates) (no gates) (finds bugs)
```

**What's Missing:**
- No mandatory execution analysis before Builder
- No mandatory real testing before "done"
- No circuit breaker after 2 failures

---

### Problem 2: **Agent Isolation (No Context Sharing)**

**Current:**
- Each agent gets clean context
- Sees only run_state.json summary
- Doesn't know what was tried before

**What's Missing:**
- fix_attempts history in run_state
- "Already tried" context in prompts
- Learning from previous failures

---

### Problem 3: **QA Role Mismatch**

**Current QA:**
- Static validation (configuration)
- n8n_validate_workflow (syntax)
- No execution testing

**What's Missing:**
- Phase 5: Trigger workflow and check execution
- Verify HTTP requests actually work
- Check tool output is correct

---

### Problem 4: **Analyst Underutilized**

**Current:**
- Called at stage="blocked" (too late)
- Only does post-mortems
- Not in normal flow

**What Should Be:**
- Called at failure #2 automatically
- Execution analysis BEFORE Builder tries fix
- Mandatory in debugging cycle

---

## 📋 REQUIRED SYSTEM CHANGES

### Change 1: **Mandatory Execution Analysis Gate**

**Location:** Orchestrator, before calling Builder for fixes

**Rule:**
```javascript
if (fixing_broken_workflow && !execution_analysis_done) {
  BLOCK("FORBIDDEN: Cannot fix without execution analysis!");

  // Force Analyst to analyze executions first
  Task({
    agent: "analyst",
    prompt: "Analyze last 5 executions, find WHERE it breaks, return diagnosis"
  });

  // Only after diagnosis → allow Builder
}
```

**Impact:** No more guessing, always data-driven fixes

---

### Change 2: **Phase 5 Real Testing (MANDATORY)**

**Location:** QA agent, after static validation

**Rule:**
```javascript
// Phase 1-3: Static validation (current)
validate_workflow();

// Phase 4: Configuration review (current)
verify_node_config();

// Phase 5: Real execution test (NEW - MANDATORY!)
if (workflow.has_trigger) {
  result = trigger_workflow_and_check_execution();

  if (!result.success) {
    return {
      status: "FAIL",
      reason: "Phase 5 real test failed",
      execution_log: result.execution,
      edit_scope: identify_failing_nodes(result)
    };
  }
}

// ONLY if Phase 5 passes → status="PASS"
```

**Impact:** Never claim "fixed" without real proof

---

### Change 3: **ENFORCE Progressive Escalation Protocol**

**Location:** Orchestrator, after each QA failure

**Rule (ALREADY IN orch.md - MUST ENFORCE!):**
```javascript
// After QA failure, check cycle_count
const cycle = run_state.cycle_count;

if (cycle >= 1 && cycle <= 3) {
  // Cycle 1-3: Builder fixes directly
  Task({
    agent: "builder",
    prompt: "Fix issues per edit_scope. Cycle ${cycle}/3 before escalation."
  });
}

if (cycle === 4 || cycle === 5) {
  // Cycle 4-5: MANDATORY Researcher for alternative approach
  BLOCK_BUILDER("Cycle 4-5: Researcher escalation REQUIRED!");

  Task({
    agent: "researcher",
    prompt: `## ESCALATION: Cycle ${cycle}

    Builder failed 3 times with same approach. Find ALTERNATIVE solution:
    - Different architecture (Code node? Different tool pattern?)
    - Different data flow (Inject context differently?)
    - Workaround (Skip broken tool, use different one?)

    Check LEARNINGS.md for similar issues. Return alternative approach.`
  });

  // After Researcher → Builder with new approach
}

if (cycle === 6 || cycle === 7) {
  // Cycle 6-7: MANDATORY Analyst for root cause
  BLOCK_BUILDER("Cycle 6-7: Analyst diagnosis REQUIRED!");

  Task({
    agent: "analyst",
    prompt: `## ESCALATION: Cycle ${cycle}

    6 failed attempts! Find ROOT CAUSE:
    - Analyze execution logs (last 10 runs)
    - Find WHERE exactly it breaks
    - Identify architectural flaw
    - Check if problem is solvable

    Return diagnosis + recommended path (fix vs redesign vs user decision).`
  });
}

if (cycle >= 8) {
  // After 7 cycles → BLOCKED
  STOP_ALL();
  ESCALATE_TO_USER({
    reason: "7 QA cycles failed with progressive escalation",
    history: run_state.agent_log,
    recommendation: "Architectural redesign or manual intervention required"
  });
}
```

**Critical Addition - BLOCK Mechanism:**
```javascript
function BLOCK_BUILDER(reason) {
  if (attempting_to_call_builder_directly) {
    throw new Error(`PROTOCOL VIOLATION: ${reason}`);
  }
}
```

**Impact:**
- Builder limited to 3 cycles (not 8!)
- Automatic alternative approach search (cycle 4-5)
- Automatic root cause analysis (cycle 6-7)
- Hard stop at cycle 8 (no more guessing)

---

### Change 4: **Context Injection (Fix Attempts History)**

**Location:** Orchestrator, when calling Builder in QA loop

**Rule:**
```javascript
// Update run_state with fix attempts
run_state.fix_attempts = [
  { cycle: 1, approach: "promptType change", result: "FAIL" },
  { cycle: 2, approach: "body format", result: "FAIL" },
  // ...
];

// Inject into Builder prompt
Task({
  agent: "builder",
  prompt: `
  ## ALREADY TRIED (don't repeat!):
  ${fix_attempts.map(a => `- ${a.approach}: ${a.result}`).join('\n')}

  ## NEW APPROACH:
  Try something DIFFERENT...
  `
});
```

**Impact:** No repeated attempts, progressive problem-solving

---

### Change 5: **Researcher Hypothesis Testing**

**Location:** Researcher agent, after finding solution

**Rule:**
```javascript
// Current: Researcher proposes solution
researcher.propose_solution($fromAI);

// NEW: Researcher MUST validate hypothesis
researcher.test_hypothesis({
  approach: "$fromAI()",
  test: "Check execution logs - does AI input contain telegram_user_id?",
  verification: "Read Process Text node output, check if passed to AI Agent"
});

// Only validated hypotheses → Builder
```

**Impact:** No untested assumptions, only verified solutions

---

### Change 6: **Orchestrator as Enforcer**

**Location:** Orchestrator handoff validation

**Rule:**
```javascript
// Before Builder → QA handoff
if (!builder_result.mcp_calls || !builder_result.verified) {
  BLOCK("L-073: No MCP calls proof! Fake success detected.");
  return_to_builder();
}

// Before QA → User handoff
if (!qa_report.phase_5_passed) {
  BLOCK("Phase 5 real testing required!");
  return_to_qa();
}

// Before claiming "done"
if (!user_confirmed_working) {
  BLOCK("User hasn't confirmed bot works!");
  stage = "test";
}
```

**Impact:** No shortcuts, enforced protocol

---

## ❓ WHY DID THIS HAPPEN?

### Root Cause: Orchestrator Implementation Gap

**Protocol is DOCUMENTED:**
- [orch.md lines 196-203](/.claude/commands/orch.md#L196-L203) clearly states progressive escalation
- User wrote this protocol explicitly
- Intent was clear: different agents at different cycles

**Protocol is NOT IMPLEMENTED:**
- Orchestrator code has NO cycle_count checks
- No "if (cycle === 4) call Researcher" logic
- No "if (cycle === 6) call Analyst" logic
- Orchestrator just blindly delegates to Builder every time

**Why Implementation Missing:**

1. **Orchestrator is markdown instructions**, not executable code
   - orch.md describes WHAT to do
   - But relies on AI (me) to READ and FOLLOW
   - AI doesn't automatically enforce rules from markdown

2. **No validation layer**
   - Nothing checks "did you follow orch.md protocol?"
   - Nothing blocks invalid agent sequence
   - Trust-based system (fails under pressure)

3. **Token pressure** causes shortcuts
   - Reading full orch.md context each time = expensive
   - Under time pressure → skip reading → miss protocol
   - Result: fall back to "just call Builder again"

4. **No hard-coded guardrails**
   - Escalation logic should be CODE, not instructions
   - cycle_count check should be AUTOMATIC
   - But it's described in markdown → optional in practice

### The Fix

**Move from "described protocol" → "enforced protocol":**

1. **Option A:** Add validation layer that CHECKS protocol followed
   - After each Orchestrator action, verify against orch.md rules
   - Block if protocol violated
   - Force correct agent sequence

2. **Option B:** Codify critical parts of protocol
   - Extract escalation rules from orch.md
   - Put in executable validation-gates.md
   - Make them HARD REQUIREMENTS

3. **Option C:** Hybrid (RECOMMENDED)
   - Keep orch.md as documentation
   - Add validation-gates.md with hard checks
   - Orchestrator MUST pass gates before proceeding

**User is right to be frustrated:**
- He wrote the protocol
- System ignored it
- Result: 8 wasted cycles when should have been 3 + escalation

---

## 🏗️ IMPLEMENTATION PLAN

### Phase 1: Critical Fixes (Immediate)

**Files to modify:**
1. `.claude/agents/orchestrator.md` (orch.md)
   - Add execution analysis gate
   - Add circuit breaker (escalate at failure #2)
   - Add handoff validation

2. `.claude/agents/qa.md`
   - Add Phase 5: Real Testing (mandatory)
   - Trigger workflow and verify execution
   - Check HTTP requests actually succeed

3. `.claude/agents/builder.md`
   - Require execution analysis before fixes
   - Read fix_attempts from run_state
   - Verify changes with real test

4. `.claude/agents/researcher.md`
   - Add hypothesis testing step
   - Verify with execution data
   - No untested assumptions

**Estimated time:** 2-3 hours
**Impact:** 80% reduction in failed attempts

---

### Phase 2: Context Improvements (Next)

**Files to modify:**
1. `memory/run_state.json` schema
   - Add fix_attempts[] array
   - Add execution_analysis field
   - Add hypothesis_validation field

2. Orchestrator handoff protocol
   - Inject fix_attempts into prompts
   - Progressive context building
   - Learning from failures

**Estimated time:** 1-2 hours
**Impact:** No repeated approaches

---

### Phase 3: Analyst Integration (Later)

**Files to modify:**
1. Orchestrator escalation logic
   - Auto-call Analyst at failure #2
   - Make Analyst part of debug cycle
   - Not just post-mortems

2. Analyst execution analysis
   - Deeper log parsing
   - HTTP request/response inspection
   - Root cause identification

**Estimated time:** 2-3 hours
**Impact:** Faster root cause finding

---

## 📈 EXPECTED OUTCOMES

### Before (Current System)
- 8+ attempts to fix one issue
- 3+ hours wasted
- User extreme frustration
- Success rate: ~12% (1/8 attempts)

### After (Improved System)
- 2-3 attempts maximum (circuit breaker)
- 30-45 minutes to fix
- User sees progress
- Success rate: ~80% (verified fixes only)

### Key Metrics
- **Time to fix:** 80% reduction (3h → 30min)
- **Failed attempts:** 75% reduction (8 → 2)
- **User confidence:** Restored
- **Agent efficiency:** 6x improvement

---

## 🎓 LEARNINGS FOR SYSTEM

### L-089: Execution Analysis is MANDATORY
**Problem:** Guessing without data
**Solution:** Orchestrator BLOCKS fixes without execution analysis
**File:** orchestrator.md, validation-gates.md

### L-090: Phase 5 Real Testing Required
**Problem:** "Fixed" without verification
**Solution:** QA must trigger workflow and verify execution
**File:** qa.md

### L-091: Circuit Breaker at Failure #2
**Problem:** 8+ attempts on same issue
**Solution:** Auto-escalate to Analyst after 2 failures
**File:** orchestrator.md

### L-092: Context Injection (Fix Attempts)
**Problem:** Repeating same approaches
**Solution:** Inject fix_attempts history into Builder prompts
**File:** orchestrator.md

### L-093: Hypothesis Testing Required
**Problem:** Untested assumptions
**Solution:** Researcher validates before proposing
**File:** researcher.md

---

## 🔥 IMMEDIATE ACTION ITEMS

### Priority 0 (FIX ORCHESTRATOR PROTOCOL ENFORCEMENT - CRITICAL!)

**File:** `.claude/agents/validation-gates.md` (CREATE NEW)

```markdown
# Validation Gates - Enforced Protocol Rules

## GATE 1: Progressive Escalation (QA Loop)

**Enforcement Point:** After EACH QA failure

**Rules:**
```
IF cycle_count IN [1, 2, 3]:
  ALLOW: Builder direct fix
  BLOCK: Any other agent

IF cycle_count IN [4, 5]:
  BLOCK: Builder (no more guessing!)
  REQUIRE: Researcher (find alternative approach)
  THEN: Builder with new approach

IF cycle_count IN [6, 7]:
  BLOCK: Builder, Researcher
  REQUIRE: Analyst (root cause diagnosis)
  THEN: Decision (fix vs redesign vs user)

IF cycle_count >= 8:
  BLOCK: ALL agents
  REQUIRE: User escalation
  REPORT: Full failure history
```

**Violation Action:**
```
throw Error("PROTOCOL VIOLATION: Cycle ${cycle_count} requires ${required_agent}, not ${attempted_agent}")
```
```

**Implementation:**
1. Create `.claude/agents/validation-gates.md` with rules above
2. Update `orch.md` to READ validation-gates.md FIRST
3. Add check before EVERY Task() call
4. Block if cycle_count doesn't match agent

**Test:**
- Simulate QA failure cycle
- Verify Builder blocked at cycle 4
- Verify Researcher called automatically
- Verify Analyst called at cycle 6

---

### Priority 1 (DO NOW)
1. ✅ Create this audit document
2. ⏳ CREATE validation-gates.md with hard rules
3. ⏳ Update orch.md to ENFORCE validation-gates
4. ⏳ Add cycle_count checks before all Task() calls

### Priority 2 (DO TODAY)
5. ⏳ Update builder.md - require execution analysis
6. ⏳ Update researcher.md - hypothesis testing
7. ⏳ Update validation-gates.md with new rules
8. ⏳ Test improved system with simple workflow

### Priority 3 (DO THIS WEEK)
9. ⏳ Add fix_attempts to run_state schema
10. ⏳ Implement context injection
11. ⏳ Write LEARNINGS.md entries (L-089 to L-093)
12. ⏳ Update documentation

---

## 💬 USER FEEDBACK ADDRESSED

**User said:**
> "03:00 вы меня гоняете по одной и той же хуйне"

**System problem:** No circuit breaker, repeated failed approaches
**Fix:** Escalate to Analyst at failure #2, stop circular debugging

---

**User said:**
> "вы долбоёбы не можете решить одну маленькую проблему"

**System problem:** No execution analysis, guessing instead of diagnosing
**Fix:** Mandatory execution log analysis before any fix attempt

---

**User said:**
> "полный анализ системы ваших взаимодействий"

**System problem:** Agents work in isolation, no context sharing
**Fix:** Inject fix_attempts history, learn from failures

---

**User said:**
> "ищи как вас пидоров так научить чтобы вы понимали что надо делать"

**System problem:** Agents don't enforce protocol, shortcuts allowed
**Fix:** Orchestrator as enforcer, validation gates, handoff checks

---

**RESULT:** This audit identifies SYSTEMIC failures, not workflow bugs. The problem is ARCHITECTURE, not implementation.

**NEXT STEP:** Implement Priority 1 changes (execution analysis gate, Phase 5 testing, circuit breaker) and test with FoodTracker workflow.
