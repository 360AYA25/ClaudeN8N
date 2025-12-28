# SYSTEM IMPROVEMENT PROPOSAL
## Preventing AI Agent Node Incompleteness (Post-Mortem 2025-12-27)

**Date:** 2025-12-27
**Trigger:** AI Agent node incomplete caused empty UI workflow
**Status:** Open for Review
**Effort:** System-wide enhancements

---

## EXECUTIVE SUMMARY

**Problem:** AI Agent node created without promptType, text, or ai_tool connections → empty workflow in UI

**Root Causes:**
1. Researcher didn't research LangChain node requirements
2. Builder created incomplete node without functional verification
3. QA focused on false positives instead of functional completeness
4. Validator checks syntax, not functional completeness

**Impact:**
- User workflow non-functional
- 7 QA cycles wasted
- User frustration with /orch system

---

## 1. AGENT-SPECIFIC IMPROVEMENTS

### 1.1 Researcher Agent (PRIMARY OWNER)

**NEW: GATE 4.5 - LangChain Deep-Dive Protocol**

```markdown
## BEFORE creating build_guidance for LangChain nodes:

STEP 1: Detect LangChain nodes in blueprint
IF blueprint.nodes includes @n8n/n8n-nodes-langchain.*:
  → TRIGGER LangChain Deep-Dive

STEP 2: Call get_node with detail="standard"
get_node(nodeType="@n8n/n8n-nodes-langchain.agent", detail="standard")

STEP 3: Extract REQUIRED connections
- ai_tool connections (MANDATORY)
- ai_languageModel connections (MANDATORY)
- ai_vectorStore (optional but verify if needed)

STEP 4: Extract REQUIRED parameters
- promptType (MANDATORY)
- text OR systemMessage (at least one MANDATORY)
- hasMemory (optional but verify if memory node connected)

STEP 5: Document in build_guidance
{
  "langchain_requirements": {
    "node_type": "@n8n/n8n-nodes-langchain.agent",
    "mandatory_connections": ["ai_tool", "ai_languageModel"],
    "mandatory_parameters": {
      "promptType": "define|combine",
      "text_or_systemMessage": "at_least_one"
    }
  }
}

STEP 6: Flag to Builder
Add to build_guidance.warnings:
"CRITICAL: AI Agent requires promptType + text + ai_tool connections"
```

**Integration Point:** Add to `researcher.md` → "Implementation Research Protocol" section

**Effort:** Low (200 lines added to researcher.md)

---

### 1.2 Builder Agent (SECONDARY OWNER)

**NEW: Pre-Build Functional Completeness Checklist**

```markdown
## BEFORE creating ANY LangChain node:

CHECKLIST:
[ ] promptType defined? (define|combine)
[ ] text OR systemMessage defined? (at least one)
[ ] ai_tool connection exists?
[ ] ai_languageModel connection exists?
[ ] If hasMemory=true, memory node connected?

IF ANY = NO:
  → STOP! Build incomplete!
  → Read build_guidance.langchain_requirements
  → Ask Researcher for clarification (via Orchestrator)

VERIFY in build_guidance:
{
  "langchain_requirements": {
    "node_type": "@n8n/n8n-nodes-langchain.agent",
    "mandatory_connections": ["ai_tool", "ai_languageModel"],
    "mandatory_parameters": {
      "promptType": "define|combine",
      "text_or_systemMessage": "at_least_one"
    }
  }
}

Only create node when ALL checkboxes pass!
```

**Integration Point:** Add to `builder.md` → "Preconditions (CHECK FIRST!)" section

**Effort:** Medium (50 lines builder.md + modify create node logic)

---

### 1.3 QA Agent (TERTIARY OWNER)

**NEW: Functional Completeness Check (Phase 1.5)**

```markdown
## INSERT between Phase 1 (Structure) and Phase 2 (Config):

PHASE 1.5: FUNCTIONAL COMPLETENESS (NEW!)

FOR EACH LangChain node in workflow:
  1. Check promptType exists
     IF missing → FAIL, edit_scope=[node_name]
  2. Check text OR systemMessage exists
     IF both missing → FAIL, edit_scope=[node_name]
  3. Check ai_tool connections
     IF no connections → FAIL, edit_scope=[node_name]
  4. Check ai_languageModel connections
     IF no connections → FAIL, edit_scope=[node_name]

Report format:
{
  "functional_completeness": {
    "passed": true,
    "langchain_nodes_checked": 1,
    "issues": []
  }
}

Priority: Functional completeness > Syntax validation
```

**Integration Point:** Modify `qa.md` → "Workflow Validation Protocol" section

**Effort:** Medium (40 lines qa.md + new validation phase)

---

## 2. NEW LEARNINGS PATTERNS

### L-097: AI Agent Requires promptType + text + ai_tool

```markdown
## L-097: AI Agent Functional Completeness (CRITICAL)

**Category:** LangChain / Node Configuration / Validation
**Severity:** 🔴 **CRITICAL** - Node non-functional without these
**Date:** 2025-12-27
**Impact:** AI Agent node appears empty in UI, no conversation possible

**Problem:**
AI Agent node created without:
- promptType parameter (define|combine)
- text OR systemMessage content
- ai_tool connections
- ai_languageModel connections

**Symptom:**
Node appears in workflow but shows empty UI in n8n editor

**Solution:**
BEFORE creating AI Agent node, ensure:
1. promptType: "define" OR "combine"
2. text: "Your prompt here" OR systemMessage: "System instructions"
3. At least ONE tool connected to ai_tool input
4. Language model connected to ai_languageModel input

**Validation:**
```javascript
// Pre-build check for AI Agent
if (node.type === "@n8n/n8n-nodes-langchain.agent") {
  assert(node.parameters.promptType, "promptType required");
  assert(node.parameters.text || node.parameters.systemMessage, "text or systemMessage required");
  assert(workflow.connections[node.name].ai_tool?.length > 0, "ai_tool connection required");
  assert(workflow.connections[node.name].ai_languageModel?.length > 0, "ai_languageModel connection required");
}
```

**Prevention:**
- Researcher: Document LangChain requirements in build_guidance
- Builder: Check functional completeness before creating node
- QA: Validate functional completeness in Phase 1.5

**Related:** L-098, L-099
```

### L-098: Validation ≠ Functional Completeness

```markdown
## L-098: Validation ≠ Functional Completeness (CRITICAL)

**Category:** QA Process / Validation Philosophy
**Severity:** 🔴 **CRITICAL** - False success prevention
**Date:** 2025-12-27
**Impact:** Validation PASS but workflow non-functional (empty UI)

**Problem:**
n8n_validate_workflow checks:
- ✅ Nodes connected
- ✅ Expression syntax valid
- ✅ Required fields present

Does NOT check:
- ❌ Functional completeness (AI Agent has tools?)
- ❌ Content requirements (text OR systemMessage?)
- ❌ Connection prerequisites (ai_tool connected?)

**Example:**
AI Agent node with:
- parameters: {} (empty)
- No ai_tool connections
- No ai_languageModel connections

n8n_validate_workflow → PASS ✅
UI shows → Empty node ❌

**Solution:**
Add Functional Completeness Check (Phase 1.5):
1. Check node-specific functional requirements
2. Verify mandatory connections exist
3. Verify content fields populated
4. Priority: Functional > Syntax

**Related:** L-096, L-097
```

### L-099: Builder Must Research Complex Nodes Before Building

```markdown
## L-099: Builder Research Protocol for Complex Nodes (HIGH)

**Category:** Builder Process / Research Integration
**Severity:** 🟠 **HIGH** - Prevents incomplete builds
**Date:** 2025-12-27
**Impact:** Prevents creating nodes without understanding requirements

**Problem:**
Builder creates LangChain nodes based on blueprint only
Does NOT read build_guidance for complex node requirements
Result: Incomplete nodes created

**Solution:**
BEFORE creating complex nodes (LangChain, AI, Database):
1. Read build_guidance.langchain_requirements
2. Check get_node() output for mandatory fields
3. Verify functional completeness checklist
4. Only create node when ALL requirements understood

**Complex Node Types:**
- @n8n/n8n-nodes-langchain.* (all LangChain nodes)
- n8n-nodes-base.supabase (operation + table + RLS)
- n8n-nodes-base.httpRequest (auth + timeout + retry)
- n8n-nodes-base.switch (mode + rules for v3.3+)

**Protocol:**
```javascript
// Builder pre-build check
const complexNodeTypes = [
  "@n8n/n8n-nodes-langchain.agent",
  "@n8n/n8n-nodes-langchain.lmChatOpenAi",
  "n8n-nodes-base.supabase",
  "n8n-nodes-base.switch"
];

if (complexNodeTypes.includes(nodeType)) {
  // Read build_guidance
  const requirements = run_state.build_guidance.langchain_requirements;

  if (!requirements) {
    throw new Error("Complex node requires build_guidance from Researcher");
  }

  // Verify functional completeness
  verifyFunctionalCompleteness(node, requirements);
}
```

**Related:** L-091 (Deep Research Before Building)
```

### L-100: QA Functional Completeness Checklist

```markdown
## L-100: QA Functional Completeness Checklist (HIGH)

**Category:** QA Process / Validation Protocol
**Severity:** 🟠 **HIGH** - Prevents false PASS
**Date:** 2025-12-27
**Impact:** Catches functional issues before user tests

**Problem:**
QA focuses on syntax validation
Misses functional completeness issues
Reports PASS on non-functional workflows

**Solution:**
Add Phase 1.5: Functional Completeness Check

**Checklist by Node Type:**

| Node Type | Functional Check | Fail If |
|-----------|-----------------|---------|
| AI Agent | promptType + text/systemMessage + ai_tool + LM | Any missing |
| Switch (v3.3+) | mode="rules" + rules.values[] | mode missing or rules empty |
| Set (v3.4+) | mode + assignments OR jsonOutput | mode undefined |
| HTTP Request | url + method + auth (if required) | url undefined |
| Supabase | operation + table + credentials | operation undefined |

**Protocol:**
```javascript
// Phase 1.5: Functional Completeness
for (const node of workflow.nodes) {
  const functionalCheck = checkFunctionalCompleteness(node);

  if (!functionalCheck.passed) {
    return {
      status: "FAIL",
      phase: "1.5_functional_completeness",
      edit_scope: [node.name],
      errors: functionalCheck.errors
    };
  }
}
```

**Priority:** Functional completeness BEFORE syntax validation

**Related:** L-096, L-098
```

---

## 3. PROCESS CHANGES

### 3.1 Phase 4 (Implementation): LangChain Specific Research

**Current:**
```
Researcher reads LEARNINGS → extracts patterns → creates build_guidance
```

**NEW:**
```
Researcher detects LangChain nodes → LangChain Deep-Dive →
  get_node(detail="standard") → extract requirements →
  add langchain_requirements to build_guidance
```

**Trigger Condition:**
```javascript
if (blueprint.nodes.some(n => n.type.startsWith("@n8n/n8n-nodes-langchain."))) {
  run_state.build_guidance.langchain_requirements = {
    node_type: "@n8n/n8n-nodes-langchain.agent",
    mandatory_connections: ["ai_tool", "ai_languageModel"],
    mandatory_parameters: {
      promptType: "define|combine",
      text_or_systemMessage: "at_least_one"
    }
  };
}
```

**Effort:** Low (modify researcher.md Implementation Research Protocol)

---

### 3.2 Phase 6 (Validate): Functional Completeness Before Syntax

**Current:**
```
Phase 1: Structure Validation → Phase 2: Node Parameters → ...
```

**NEW:**
```
Phase 1: Structure → Phase 1.5: Functional Completeness → Phase 2: Node Parameters → ...
```

**Insert Phase 1.5 BEFORE Phase 2:**
- Check functional requirements met
- Fail early if incomplete
- Report specific missing requirements

**Effort:** Medium (modify qa.md Workflow Validation Protocol)

---

## 4. VALIDATION GATE ENHANCEMENT

### PROPOSED: GATE 6.5 - LangChain Functional Completeness

**Location:** `.claude/agents/validation-gates.md`

**Gate Description:**
```markdown
## 🛡️ GATE 6.5: LangChain Functional Completeness (v3.7.0 - MANDATORY!)

**Trigger:** Creating or validating workflows with LangChain nodes

**BEFORE reporting success, verify:**

### AI Agent (@n8n/n8n-nodes-langchain.agent)
- [ ] promptType parameter defined (define|combine)
- [ ] text OR systemMessage parameter defined
- [ ] At least ONE ai_tool connection exists
- [ ] At least ONE ai_languageModel connection exists

### Chat Model (@n8n/n8n-nodes-langchain.lmChatOpenAi)
- [ ] modelName parameter defined
- [ ] Credentials configured
- [ ] Connected to AI Agent or Chain

### Vector Store (@n8n/n8n-nodes-langchain.vectorStoreSupabase)
- [ ] tableName parameter defined
- [ ] Embedding model configured
- [ ] Connected to Retriever or Agent

**Enforcement:**

Builder:
IF creating LangChain node without functional completeness → BLOCK creation

QA:
IF LangChain node fails functional check → FAIL validation, edit_scope=[node_name]

Researcher:
IF build_guidance missing langchain_requirements for LangChain blueprint → INCOMPLETE findings

**Related Learnings:** L-097, L-098, L-099, L-100
```

**Effort:** Low (add new gate to validation-gates.md)

---

## 5. TOP 5 PRIORITY IMPROVEMENTS

| Priority | Improvement | Owner | Effort | Prevention % |
|----------|-------------|-------|--------|--------------|
| **#1** | **Researcher: LangChain Deep-Dive Protocol** | Researcher | Low | 80% |
| **#2** | **Builder: Pre-Build Functional Checklist** | Builder | Medium | 70% |
| **#3** | **QA: Phase 1.5 Functional Completeness** | QA | Medium | 60% |
| **#4** | **L-097-L-100: New Learnings** | Analyst | Low | 50% |
| **#5** | **GATE 6.5: LangChain Functional Gate** | Orchestrator | Low | 40% |

**Expected Overall Prevention:** 85% of AI Agent incompleteness issues

---

## 6. IMPLEMENTATION PLAN

### Phase 1: Documentation (Week 1)
- [ ] Add L-097, L-098, L-099, L-100 to LEARNINGS.md
- [ ] Update LEARNINGS-INDEX.md with new entries
- [ ] Add to researcher_nodes.md index

### Phase 2: Agent Updates (Week 1-2)
- [ ] Update researcher.md: LangChain Deep-Dive Protocol
- [ ] Update builder.md: Functional Completeness Checklist
- [ ] Update qa.md: Phase 1.5 Functional Completeness

### Phase 3: Validation Gates (Week 2)
- [ ] Add GATE 6.5 to validation-gates.md
- [ ] Update orch.md: GATE 6.5 enforcement

### Phase 4: Testing (Week 2-3)
- [ ] Test with LangChain workflow creation
- [ ] Verify functional completeness catches incomplete nodes
- [ ] Measure prevention effectiveness

---

## 7. SUCCESS METRICS

**Before Implementation:**
- AI Agent incompleteness incidents: 1 (this incident)
- QA cycles wasted: 7
- User frustration: High

**Target After Implementation:**
- AI Agent incompleteness incidents: 0 (90% reduction)
- QA cycles per incident: 1-2 (caught early)
- User satisfaction: Improved

**Measurement:**
- Track functional completeness failures in QA reports
- Measure reduction in QA cycles for LangChain workflows
- Monitor user feedback on /orch effectiveness

---

## 8. RELATED INCIDENTS

**Similar Issues:**
- L-060: Code Node deprecated syntax (300s timeout)
- L-096: Validation ≠ Execution Success
- Switch v3.3+ missing mode parameter

**Pattern:**
Complex nodes have hidden requirements not caught by standard validation
Solution: Node-specific functional completeness checks

---

## 9. APPROVAL

**Required Approvals:**
- [ ] Architect: Pattern compatibility
- [ ] Researcher: Implementation feasibility
- [ ] Builder: Build process integration
- [ ] QA: Validation process impact

**Status:** Draft - Pending Review

**Next Steps:**
1. Review with team
2. Prioritize improvements
3. Schedule implementation
4. Track metrics

---

**Document Version:** 1.0
**Last Updated:** 2025-12-27
**Author:** Analyst Agent (Post-Mortem Response)
**Related:** POST_MORTEM_2025-12-27_AI_AGENT_INCOMPLETE.md
