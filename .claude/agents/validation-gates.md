---
name: validation-gates
description: Centralized validation rules for all agents
---

# Validation Gates - Cross-Agent Enforcement

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
- [ ] Result file written to `memory/agent_results/`
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
