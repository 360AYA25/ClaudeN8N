---
name: validation-gates
description: Centralized validation rules for all agents
---

# Validation Gates - Cross-Agent Enforcement

> **UPDATED:** 2025-12-04 - Added Priority 0 Critical Enforcement Gates
> **Source:** SYSTEM_AUDIT_AGENT_FAILURES.md analysis

---

## 🚨 PRIORITY 0: CRITICAL ENFORCEMENT GATES

**Context:** Task 2.4 revealed systemic failures - Orchestrator ignored its own progressive escalation protocol, causing 8 wasted cycles instead of 3 + escalation. These gates MUST be checked before EVERY agent delegation.

**Authority:** Orchestrator MUST enforce these gates. Violations = system stop.

---

### GATE 1: Progressive Escalation (QA Loop) - MANDATORY!

**Enforcement Point:** After EACH QA failure

**Protocol Source:** [orch.md lines 196-203](../commands/orch.md#L196-L203)

**Problem Solved:** Builder trying 8+ times with same approach (Task 2.4 failure)

**Rules by Cycle Count:**

```bash
# Cycle 1-3: Builder Direct Fix
IF cycle_count IN [1, 2, 3]:
  ALLOW: Builder (direct fix attempts)
  BLOCK: Researcher (too early), Analyst (too early)
  Rationale: Simple fixes first, Builder may succeed quickly

# Cycle 4-5: Researcher Alternative Approach (MANDATORY!)
IF cycle_count IN [4, 5]:
  BLOCK: Builder (exhausted direct fixes!)
  REQUIRE: Researcher FIRST (find alternative approach)
  THEN: Builder with new approach from Researcher

  Rationale: 3 failures = current approach wrong, need different solution

  Researcher Prompt:
  "Builder failed 3 times. Find ALTERNATIVE approach:
   - Different architecture (Code node? Different tool?)
   - Different data flow (Inject context differently?)
   - Workaround (Skip broken tool, use alternative?)
   Check LEARNINGS.md for similar issues."

# Cycle 6-7: Researcher Deep Dive (MANDATORY!)
IF cycle_count IN [6, 7]:
  BLOCK: Builder (no more guessing!)
  REQUIRE: Researcher FIRST (deep root cause analysis)
  THEN: Decision (fix vs redesign vs user escalation)

  Rationale: 5 failures = architectural issue, need deep analysis

  Researcher Prompt:
  "6 failed attempts! Find ROOT CAUSE:
   - Analyze execution logs (last 10 runs)
   - Find WHERE exactly it breaks
   - Identify architectural flaw
   - Check if problem is solvable
   - Read LEARNINGS.md for known issues"

# Cycle 8+: BLOCKED - User Escalation
IF cycle_count >= 8:
  BLOCK: ALL agents (no more attempts!)
  SET: stage = "blocked"
  REPORT: Full failure history + recommendation
```

**Orchestrator Check (before every Task call in QA loop):**

```bash
cycle=$(jq -r '.cycle_count // 0' ${project_path}/.n8n/run_state.json)

# Cycle 4-5: MUST call Researcher first
if [ "$cycle" -ge 4 ] && [ "$cycle" -le 5 ]; then
  if [ "$calling_builder_without_researcher" = true ]; then
    echo "🚨 GATE 1 VIOLATION: Cycle $cycle requires Researcher FIRST!"
    exit 1
  fi
fi

# Cycle 6-7: MUST call Researcher first (deep dive)
if [ "$cycle" -ge 6 ] && [ "$cycle" -le 7 ]; then
  if [ "$calling_builder_without_researcher_deep_dive" = true ]; then
    echo "🚨 GATE 1 VIOLATION: Cycle $cycle requires Researcher deep dive FIRST!"
    exit 1
  fi
fi

# Cycle 8+: NO more attempts
if [ "$cycle" -ge 8 ]; then
  echo "🚨 GATE 1 VIOLATION: Cycle 8+ blocked! User escalation required."
  exit 1
fi
```

---

### GATE 2: Execution Analysis Requirement

**Enforcement Point:** Before calling Builder for ANY fix to existing workflow

**Problem Solved:** Builder guessing without data (Attempts 1-4, 6-8 in Task 2.4)

**Rule:**

```bash
IF fixing_broken_workflow:
  IF execution_analysis_done = false:
    BLOCK: Builder (cannot fix without diagnosis!)
    REQUIRE: Researcher execution analysis FIRST
    THEN: Builder with diagnosis results

  Rationale: No guessing - always data-driven fixes
```

**Orchestrator Check:**

```bash
stage=$(jq -r '.stage' ${project_path}/.n8n/run_state.json)
workflow_id=$(jq -r '.workflow_id' ${project_path}/.n8n/run_state.json)

# Check if fixing existing workflow (not creating new)
if [ "$stage" = "build" ] && [ -f "${project_path}/.n8n/snapshots/$workflow_id/canonical.json" ]; then
  # This is a FIX, not new build

  execution_analysis=$(jq -r '.execution_analysis.completed // false' ${project_path}/.n8n/run_state.json)

  if [ "$execution_analysis" != "true" ]; then
    echo "🚨 GATE 2 VIOLATION: Cannot fix without execution analysis!"
    echo "Required: Call Researcher to analyze last 5 executions FIRST."
    exit 1
  fi
fi
```

**Required Fields in run_state_active.json:**

```json
{
  "execution_analysis": {
    "completed": true,
    "researcher_agent": "researcher",
    "timestamp": "2025-12-04T15:30:00Z",
    "findings": {
      "break_point": "AI Agent node - input field missing telegram_user_id",
      "root_cause": "Prepare Message Data passes only text, not full context",
      "failed_executions": 5
    },
    "diagnosis_file": "${project_path}/.n8n/agent_results/{workflow_id}/execution_analysis.json"
  }
}
```

---

### GATE 3: Phase 5 Real Testing (QA Requirement)

**Enforcement Point:** Before QA reports status = "PASS"

**Problem Solved:** "Fixed" without verification (Builder said "done", bot still silent)

**Rule:**

```bash
IF qa_validation_complete:
  IF workflow.has_trigger:
    IF phase_5_real_test NOT executed:
      BLOCK: QA from reporting "PASS"
      REQUIRE: Trigger workflow and verify execution

  Rationale: Static validation ≠ real functionality
```

**QA Must Execute:**

**Phase 1-4:** Static validation (configuration, syntax, connections)

**Phase 5 (MANDATORY):** Real execution testing

```bash
# If workflow has trigger
if workflow_has_trigger; then
  # Trigger workflow
  execution_id=$(n8n_test_workflow --workflow-id "$workflow_id" --wait)

  # Check execution result
  status=$(n8n_executions --action get --id "$execution_id" | jq -r '.status')

  if [ "$status" != "success" ]; then
    # Phase 5 FAILED
    qa_report.status = "FAIL"
    qa_report.phase_5_failure = {
      "execution_id": "$execution_id",
      "status": "$status"
    }
  fi
fi

# ONLY if Phase 5 passes → status = "PASS"
```

**Orchestrator Check:**

```bash
qa_status=$(jq -r '.qa_report.status' ${project_path}/.n8n/run_state.json)

if [ "$qa_status" = "PASS" ]; then
  phase_5_executed=$(jq -r '.qa_report.phase_5_executed // false' ${project_path}/.n8n/agent_results/$workflow_id/qa_report.json)

  if [ "$phase_5_executed" != "true" ]; then
    echo "🚨 GATE 3 VIOLATION: QA reported PASS without Phase 5 real testing!"
    exit 1
  fi
fi
```

---

### GATE 4: Context Injection (Fix Attempts History)

**Enforcement Point:** Before calling Builder in QA loop (cycle 2+)

**Problem Solved:** Repeating same failed approaches (Attempts 1-3 repeated patterns)

**Rule:**

```bash
IF cycle_count >= 2:
  IF fix_attempts.length = 0:
    BLOCK: Builder (no context about previous failures!)
    REQUIRE: Inject fix_attempts history into prompt

  Rationale: Prevent repeating same failed approaches
```

**Required Context in Builder Prompt (cycle 2+):**

```markdown
## ALREADY TRIED (don't repeat!):
- Cycle 1: promptType change → FAIL (field contract mismatch)
- Cycle 2: body format jsonBody→parametersBody → FAIL (still wrong)

## WHY THEY FAILED:
- Approach 1: Changed wrong field
- Approach 2: Didn't check execution logs

## NEW APPROACH:
Try something DIFFERENT based on execution analysis...
```

**Orchestrator Check:**

```bash
cycle=$(jq -r '.cycle_count // 0' ${project_path}/.n8n/run_state.json)

if [ "$cycle" -ge 2 ]; then
  fix_attempts=$(jq -r '.fix_attempts // []' ${project_path}/.n8n/run_state.json)

  if [ "$fix_attempts" = "[]" ]; then
    echo "🚨 GATE 4 VIOLATION: Cycle $cycle requires fix_attempts context!"
    exit 1
  fi
fi
```

---

### GATE 5: MCP Call Verification (L-074)

**Enforcement Point:** Before accepting Builder result as "done"

**Problem Solved:** Fake success without real MCP calls (L-073 pattern)

**Rule:**

```bash
IF builder_reports_done:
  IF mcp_calls.length = 0:
    BLOCK: Accept as done
    REASON: Fake success (L-073 pattern)
    REQUIRE: Builder provide MCP call proof

  Rationale: Files can be faked, only MCP calls prove reality
```

**Orchestrator Check:**

```bash
builder_status=$(jq -r '.build_result.status' ${project_path}/.n8n/agent_results/$workflow_id/build_result.json)

if [ "$builder_status" = "success" ]; then
  mcp_calls=$(jq -r '.build_result.mcp_calls // []' ${project_path}/.n8n/agent_results/$workflow_id/build_result.json)

  if [ "$mcp_calls" = "[]" ]; then
    echo "🚨 GATE 5 VIOLATION: Builder reported success without MCP call proof!"
    exit 1
  fi

  # Verify at least one create/update call
  has_mutation=$(echo "$mcp_calls" | jq '[.[] | select(.tool | test("create|update|autofix"))] | length > 0')

  if [ "$has_mutation" != "true" ]; then
    echo "🚨 GATE 5 VIOLATION: No create/update MCP calls found!"
    exit 1
  fi
fi
```

---

### GATE 6: Researcher Hypothesis Validation

**Enforcement Point:** Before Researcher proposes solution to Builder

**Problem Solved:** Untested assumptions (Researcher proposed $fromAI() without verifying)

**Rule:**

```bash
IF researcher_proposes_solution:
  IF hypothesis_tested = false:
    BLOCK: Researcher proposal
    REQUIRE: Validate hypothesis with execution data

  Rationale: No untested assumptions, only verified solutions
```

**Required Validation Fields:**

```json
{
  "research_findings": {
    "status": "complete",
    "proposed_solution": "$fromAI() to access telegram_user_id",
    "hypothesis_validated": true,
    "validation_method": "Checked execution logs - Process Text passes full $json",
    "validation_result": "FAIL - AI Agent receives only $json.data (text)",
    "alternative_approach": "Use Set node to restructure data before AI Agent"
  }
}
```

**Orchestrator Check:**

```bash
researcher_status=$(jq -r '.research_findings.status' ${project_path}/.n8n/agent_results/$workflow_id/research_findings.json)

if [ "$researcher_status" = "complete" ]; then
  hypothesis_validated=$(jq -r '.research_findings.hypothesis_validated // false' ${project_path}/.n8n/agent_results/$workflow_id/research_findings.json)

  if [ "$hypothesis_validated" != "true" ]; then
    echo "🚨 GATE 6 VIOLATION: Researcher proposed solution without testing hypothesis!"
    exit 1
  fi
fi
```

---

## 📊 Critical Gates Summary

| Gate # | Enforces | Prevents | Impact |
|--------|----------|----------|--------|
| **GATE 1** | Progressive escalation | 8+ Builder cycles | 75% cycle reduction |
| **GATE 2** | Execution analysis | Guessing without data | 80% time savings |
| **GATE 3** | Phase 5 real testing | Fake "fixed" claims | 100% deploy confidence |
| **GATE 4** | Fix attempts history | Repeated failures | No circular debugging |
| **GATE 5** | MCP call proof | Fake success (L-073) | L-074 compliance |
| **GATE 6** | Hypothesis validation | Wrong solutions | 80% success rate |

**Expected Outcomes:**
- Failed attempts: 8 → 2-3 (75% reduction)
- Time to fix: 3h → 30min (80% reduction)
- Success rate: 12% → 80%

---

## Stage Transition Gates

### Gate: clarification → research
- [ ] User requirements captured
- [ ] Symptoms documented (if bug/fix request)
- [ ] Expected behavior defined

### Gate: research → decision
- [ ] Search completed (local → existing → templates → nodes)
- [ ] fit_score calculated
- [ ] research_findings complete

### Gate: decision → implementation
- [ ] User approved approach
- [ ] Credentials discovered
- [ ] Blueprint created

### Gate: implementation → build
- [ ] ✅ **EXECUTION DATA ANALYZED** (if debugging! - L-067 two-step OK)
- [ ] ✅ **Hypothesis validated with MCP tools**
- [ ] ✅ **build_guidance created with node configs**
- [ ] ✅ **LEARNINGS checked for similar issues**
- [ ] Confidence level: HIGH (80%+)

**L-067 Mode Selection (execution analysis):**
- ⚠️ Gates check that analysis WAS DONE, not HOW (mode)
- ✅ `mode="summary"` + `mode="filtered"` = complete analysis
- ❌ DO NOT require `mode="full"` (crashes on large workflows)

### Gate: build → validate
- [ ] ✅ **Workflow created/updated via curl**
- [ ] ✅ **Version ID changed**
- [ ] ✅ **Post-build verification passed**
- [ ] ✅ **Expected changes confirmed in workflow JSON**
- [ ] No rollback detected

### Gate: validate → test
- [ ] ✅ **Structure validation passed**
- [ ] ✅ **NODE parameters validated** (ALL modified nodes!)
- [ ] ✅ **REQUIRED parameters present** (mode, path, etc.)
- [ ] ✅ **Connections format verified** (node.name not id)
- [ ] No validation errors

### Gate: test → complete
- [ ] Test execution successful
- [ ] Execution comparison done (before/after)
- [ ] No regressions
- [ ] User confirmed working

---

## Node-Specific Validation Rules

### Switch Node (n8n-nodes-base.switch v3.3+)
```javascript
REQUIRE: node.parameters.mode === "rules"
REQUIRE: node.parameters.rules.values.length > 0
WARN_IF: node.parameters.options.fallbackOutput === undefined
```

**Rationale:** Switch typeVersion 3.3+ requires explicit `mode` parameter for multi-way routing. Without it, Switch evaluates conditions but does NOT route data to downstream nodes (silent failure).

### Webhook Node (n8n-nodes-base.webhook)
```javascript
REQUIRE: node.parameters.path (must start with /)
REQUIRE: node.parameters.httpMethod
REQUIRE: node.parameters.responseMode (for sync webhooks)
```

**Rationale:** Missing path or httpMethod causes webhook registration to fail silently.

### AI Agent Node (@n8n/n8n-nodes-langchain.agent)
```javascript
REQUIRE: node.parameters.promptType
REQUIRE: node.parameters.text OR systemMessage
REQUIRE: at least 1 tool connected (ai_tool connection)
REQUIRE: 1 language model connected (ai_languageModel)
```

**Rationale:** AI Agent requires prompt definition and at least one tool + language model to function.

### HTTP Request Node (n8n-nodes-base.httpRequest)
```javascript
REQUIRE: node.parameters.url
REQUIRE: node.parameters.method (default: GET)
WARN_IF: authentication enabled but credentials missing
```

### Supabase Node (n8n-nodes-base.supabase)
```javascript
REQUIRE: node.parameters.operation
REQUIRE: node.parameters.tableId (for table operations)
REQUIRE: credentials.supabaseApi
```

### Code Node (n8n-nodes-base.code)
```javascript
REQUIRE: node.parameters.jsCode OR pythonCode
WARN_IF: code length > 1000 lines (performance concern)
```

---

## Cross-Agent Validation

### Researcher → Builder Handoff
**Before Builder can execute:**
- [ ] Researcher provided `build_guidance` file
- [ ] Node configurations validated with `get_node`
- [ ] Hypothesis confidence >= 80% OR alternative hypotheses provided
- [ ] `edit_scope` defined (which nodes to modify)

**Orchestrator MUST verify these before calling Builder!**

### Builder → QA Handoff
**Before QA can validate:**
- [ ] Builder provided verification report
- [ ] Version ID confirmed changed
- [ ] Result file written to `${project_path}/.n8n/agent_results/`
- [ ] No rollback detected
- [ ] `expected_changes` documented

**Orchestrator MUST check verification report before calling QA!**

### QA → User Handoff
**Before declaring "ready for deploy":**
- [ ] QA checklist 100% complete
- [ ] Execution test passed
- [ ] `ready_for_deploy: true`
- [ ] No critical/blocking errors

---

## Circuit Breakers

### Same Hypothesis Twice
```javascript
if (cycle >= 2 && current_hypothesis === previous_hypothesis) {
  ESCALATE_TO_L4();
  BLOCK_FURTHER_FIXES();
  REASON: "Not learning from failures - same diagnosis repeated";
}
```

**Action:** Analyst audits methodology, proposes alternative approach.

### 3 QA Failures in a Row
```javascript
if (qa_fail_count >= 3) {
  ESCALATE_TO_L4();
  ANALYST_AUDIT_METHODOLOGY();
  REASON: "QA failing repeatedly - systematic issue";
}
```

**Action:** Analyst reviews QA validation results, identifies pattern.

### Researcher Confidence Below 50%
```javascript
if (researcher_confidence < 0.5) {
  REQUIRE_ANALYST_REVIEW();
  PROVIDE_ALTERNATIVE_HYPOTHESES();
  REASON: "Low confidence diagnosis - high risk of failure";
}
```

**Action:** Analyst validates hypothesis before Builder proceeds.

### Version Rollback Detected
```javascript
if (workflow.versionCounter < previous_counter) {
  CRITICAL_ALERT();
  STOP_BUILD_CYCLE();
  NOTIFY_USER();
  REASON: "User manually reverted changes in UI";
}
```

**Action:** Report to user, await instructions.

### Execution Analysis Skipped
```javascript
if (user_reports_broken && !execution_data_analyzed) {
  BLOCK_BUILD_STAGE();
  REQUIRE_EXECUTION_ANALYSIS();
  REASON: "Cannot diagnose without execution data";
}

// L-067: Check analysis was done, NOT which mode was used
// Valid analysis = (summary called OR filtered called)
// NOT: mode === "full" (which crashes on large workflows!)
```

**Action:** Force Researcher to get execution data first (L-067 two-step OK).

---

## Validation Profiles

### Profile: STRICT (Production Workflows)
- All gates MANDATORY
- Circuit breakers ACTIVE
- Zero tolerance for missing parameters
- Execution testing REQUIRED

### Profile: DEVELOPMENT (Testing/Experimental)
- Gates enforced but warnings allowed
- Circuit breakers ACTIVE but delayed (5 cycles instead of 3)
- Missing non-critical parameters → WARN instead of FAIL
- Execution testing OPTIONAL

### Profile: EMERGENCY (Critical Hotfix)
- Minimal gates only (no hypothesis validation)
- Circuit breakers DISABLED
- Fast path for simple fixes
- **USE WITH CAUTION** - only for critical production issues

---

## Error Classification

### CRITICAL (Block progression)
- Missing REQUIRED parameters (Switch mode, Webhook path)
- Version rollback detected
- Execution data shows regression
- Hypothesis confidence < 50%

### WARNING (Allow with confirmation)
- Old typeVersion (but working)
- Missing OPTIONAL parameters (fallbackOutput)
- Low test coverage
- Performance concerns (large code blocks)

### INFO (Log only)
- Using deprecated but supported features
- Suboptimal patterns (but functional)
- Token usage warnings

---

## Enforcement Mechanism

**Orchestrator enforces gates via:**

```javascript
function enforce_gate(from_stage, to_stage, run_state) {
  const gate_checklist = GATES[`${from_stage}_to_${to_stage}`];

  for (const requirement of gate_checklist) {
    if (!check_requirement(requirement, run_state)) {
      BLOCK_TRANSITION({
        from: from_stage,
        to: to_stage,
        failed_requirement: requirement,
        message: "Gate requirement not met - cannot proceed",
        required_action: get_resolution_action(requirement)
      });
      return false;
    }
  }

  return true; // All gates passed
}
```

**Agents cannot bypass gates** - Orchestrator is the single enforcement point.

---

## Metrics & Monitoring

### Success Metrics (track these)
- % of workflows passing all gates on first try
- Average cycles to completion (target: <2)
- Circuit breaker trigger rate (target: <10%)
- Execution analysis compliance (target: 100% when debugging)

### Failure Patterns (analyze monthly)
- Which gate fails most often?
- Which agent causes most failures?
- Which node types cause validation issues?
- Token waste on failed cycles

---

**Last Updated:** 2025-11-28
**Version:** 1.0.0
**Status:** Production
