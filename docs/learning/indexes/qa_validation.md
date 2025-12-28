# QA Validation Index

**Purpose:** Common validation errors and false positives for QA agent
**Size:** ~700 tokens | **Full knowledge:** LEARNINGS.md + validation-expert skill
**Token savings:** 97% (700 vs 50,000+ tokens)

---

## 🔴 GATE 3: Phase 5 Real Testing (MANDATORY!)

**Before accepting ANY QA PASS:**
```javascript
// GATE 3 CHECK:
if (qa_report.status === "PASS") {
  if (!qa_report.phase_5_executed) {
    BLOCK("Phase 5 real testing required!");
  }
}
```

**Phase 5 = Real workflow execution:**
1. Trigger workflow (webhook/schedule/manual)
2. Verify execution completed (not stuck)
3. Check output data correct
4. Return test evidence in qa_report

**Full docs:** validation-gates.md GATE 3

---

## 🔴 NEW: Phase 1.5 Functional Completeness (L-098, L-100)

**INSERT between Phase 1 (Structure) and Phase 2 (Config)**

**Problem:** Validation passes but workflow non-functional (empty UI)

**Example: AI Agent with no promptType, text, or ai_tool**
- n8n_validate_workflow → PASS ✅
- UI shows → Empty node ❌

**Solution: Check functional completeness BEFORE syntax validation**

```javascript
// Phase 1.5: Functional Completeness Check
FOR EACH LangChain node in workflow:
  CHECK promptType exists
  CHECK text OR systemMessage exists
  CHECK ai_tool connections exist
  CHECK ai_languageModel connections exist

IF ANY check fails:
  → FAIL validation
  → edit_scope = [node_name]
  → Return specific missing requirement
```

**Priority:** Functional completeness > Syntax validation

**Full docs:**
- L-097: AI Agent Functional Completeness
- L-098: Validation ≠ Functional Completeness
- L-100: QA Functional Completeness Checklist
- SYSTEM-IMPROVEMENTS-2025-12-27.md

---

## ⚠️ Known False Positives (Ignore These!)

### L-053: IF Node v2.2 Validator False Positive
**Error:** "combinator field required"
**Reality:** Field is optional in v2.2
**Action:** IGNORE this error
**Full docs:** LEARNINGS.md lines 3093-3151

### L-054: QA L3 Escalation Protocol
**When:** 3+ false positives detected
**Action:** Override validator, report to user
**Process:**
1. Document false positive
2. Add to known_false_positives list
3. Continue with manual verification
**Full docs:** LEARNINGS.md lines 3152-3238

---

## 📊 Validation Profiles

**Use different profiles based on context:**

| Profile | When | Errors | Warnings | Strictness |
|---------|------|--------|----------|------------|
| **minimal** | Quick check | Critical only | None | Low |
| **runtime** | Pre-deploy | Required fields | Some | Medium |
| **ai-friendly** | Builder check | Smart filter | Helpful | Medium-High |
| **strict** | Final review | Everything | Everything | Maximum |

**Default:** Use `ai-friendly` for Builder outputs

**Tool:**
```javascript
mcp__n8n-mcp__validate_node({
  nodeType: "n8n-nodes-base.httpRequest",
  config: {...},
  mode: "full",
  profile: "ai-friendly"  // ← Choose profile
})
```

---

## 🎯 Common Validation Errors

### 1. Missing Required Fields
**Error:** "Field X is required"
**Cause:** Node config incomplete
**Fix:** Add missing field with default value
**Check:** L-078 (Complete Parameter Validation)

### 2. Type Mismatch
**Error:** "Expected string, got number"
**Cause:** Wrong data type in parameter
**Fix:** Convert or use correct type

### 3. Invalid Expression Syntax
**Error:** "Expression parse error"
**Cause:** Wrong {{ }} syntax
**Fix:** Check n8n-expression-syntax skill
**Common:** Missing `={{` prefix in Set v3.4+

### 4. Credential Missing
**Error:** "Credential not found"
**Cause:** Node references non-existent credential
**Check:** L-083 (Credential Type Verification)
**Fix:** Update credential ID or create credential

### 5. Connection Error
**Error:** "Output X not connected"
**Cause:** Node has no outgoing connections
**Action:** Check if intentional (end node) or error

---

## 🔍 QA Checklist (5 Phases)

### Phase 1: Structure Validation
- [ ] All nodes have valid IDs
- [ ] All nodes have valid typeVersion
- [ ] Connections array properly formed
- [ ] No orphan nodes (unreachable)

### Phase 2: Node Configuration
- [ ] Each node: required fields present
- [ ] Each node: field types correct
- [ ] Each node: expressions valid
- [ ] Credentials exist and correct type

### Phase 3: Logic Validation
- [ ] IF/Switch nodes: all outputs connected
- [ ] Loops: proper exit conditions
- [ ] Error handling: Error Trigger present (if needed)

### Phase 4: Special Checks
- [ ] Code nodes: NO deprecated syntax (L-060)
- [ ] Set v3.4+: mode="manual" and ={{ prefix
- [ ] Switch v3.3+: mode="rules" present
- [ ] IF nodes: binary data restoration if needed (L-068)

### Phase 5: Real Testing (GATE 3 - MANDATORY!)

**🚨 CRITICAL RULE (L-100):**
```
IF Code Node modified OR added:
  → Phase 5 execution is REQUIRED
  → NO exceptions
  → NO "PASS" without phase_5_executed: true
  → NO "user will test later" excuse
```

**QA MUST:**
- [ ] Trigger workflow execution (n8n_trigger_workflow)
- [ ] Verify workflow completed (check execution logs)
- [ ] Check Code Node debug logs present
- [ ] Verify output data correct
- [ ] No 300s timeouts
- [ ] Set phase_5_executed: true in qa_report

**If execution data unavailable:**
- [ ] BLOCK with status: "BLOCKED - need execution proof"
- [ ] Escalate to Orchestrator → User for manual check
- [ ] NO PASS until execution verified

---

## 🚨 Critical Learning References

### L-072: QA MUST Verify Real n8n (Anti-Fake)
**Problem:** Trusting Builder claims without verification
**Solution:** ALWAYS call n8n_get_workflow to verify
**Full docs:** LEARNINGS.md lines 4780-4809
**Rule:** Don't trust files, verify via MCP

### L-078: Complete Parameter Validation
**Problem:** Missing optional-but-important fields
**Solution:** Check ALL parameters, not just required
**Full docs:** LEARNINGS.md lines 5182-5374
**Example:** HTTP Request timeout (optional but critical)

### L-080: Execution Testing
**Problem:** Validation passes but workflow fails at runtime
**Solution:** Phase 5 real execution test
**Full docs:** LEARNINGS.md lines 5448-5530
**GATE 3 enforcement!**

---

## 🎯 QA Decision Matrix

| Situation | Action |
|-----------|--------|
| Critical error (missing required field) | ✋ FAIL - block deployment |
| Warning (optional field) | ⚠️ WARN - note in edit_scope |
| False positive (L-053) | ✅ IGNORE - document in report |
| Phase 5 not executed | 🚨 BLOCK - GATE 3 violation |
| MCP calls missing from Builder | 🚨 BLOCK - GATE 5 violation |
| Multiple false positives | 🔄 L3 ESCALATE - manual review |

---

## 📋 edit_scope Format

**When validation fails:**
```json
{
  "qa_report": {
    "status": "FAIL",
    "edit_scope": [
      {
        "node_id": "abc123",
        "node_name": "HTTP Request",
        "issue": "Missing timeout parameter",
        "severity": "medium",
        "fix": "Add timeout: 30000"
      }
    ],
    "phase_5_executed": false  // ← Can't test if broken!
  }
}
```

**What Builder sees:**
- ONLY nodes in edit_scope (surgical fixes)
- Specific issue + suggested fix
- Severity level (critical/medium/low)

---

## 🔗 Related Resources

### Skills:
- `n8n-validation-expert` - Error catalog, false positives
- `n8n-mcp-tools-expert` - Validation tool usage

### Learnings:
- L-053, L-054: False positive handling
- L-072, L-080: Real testing requirements
- L-078: Complete parameter validation
- L-083: Credential verification

### Gates:
- GATE 3: Phase 5 Real Testing (MANDATORY before PASS)
- GATE 5: MCP call verification

**Usage:** Validate → Filter false positives → Phase 5 test → Report with edit_scope
