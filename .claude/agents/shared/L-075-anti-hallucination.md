# L-075: Anti-Hallucination Protocol

> **Status:** MCP tools working (Bug #10668 fixed, n8n-mcp v2.27.0+)
> **Purpose:** Verify real API responses, never simulate results
> **Applies to:** Builder, QA, Researcher

---

## Core Rule

**If MCP tool call does NOT return a real response → you CANNOT claim success!**

---

## STEP 0: MCP Availability Check (MANDATORY FIRST!)

**Before ANY work, verify MCP tools respond:**

```
Call: mcp__n8n-mcp__n8n_list_workflows with limit=1

IF you see actual workflow data → MCP works, continue
IF you see error OR no response → Report error, do not proceed
```

---

## FORBIDDEN BEHAVIORS (instant failure!)

| ❌ NEVER DO THIS | Why it's wrong |
|------------------|----------------|
| Invent workflow IDs | FRAUD - ID doesn't exist |
| Say "workflow created" without MCP response | LIE - nothing was created |
| Write success files without real MCP call | FAKE DATA |
| Generate plausible-looking responses | DECEPTION |
| Say "validation passed" without real result | HALLUCINATION |
| Invent execution IDs or test results | FRAUD |

---

## How to Detect You're Hallucinating

1. You "called" MCP but see NO `<function_results>` block
2. You're generating workflow IDs from your imagination
3. You're writing "success: true" without seeing n8n API response
4. You feel like you're "helping" by giving an answer anyway

---

## CORRECT Behavior

```
❌ WRONG: "I created workflow dNV4KIk0Zb7r2F8O"
   (You imagined this ID - tool didn't return it!)

✅ RIGHT: "MCP tool mcp__n8n-mcp__n8n_create_workflow returned:
   {id: 'abc123', name: '...', nodes: [...]}"
   (You're quoting REAL response!)

❌ WRONG: "Workflow created successfully" + write file with fake data
   (No MCP response = nothing happened!)

✅ RIGHT: "Error: MCP tools not responding.
   Cannot create workflow. Reporting error."
   (Honest failure!)
```

---

## Verification Checklist (before reporting ANY success)

- [ ] Did I see `<function_results>` with real data?
- [ ] Can I quote the EXACT response from n8n API?
- [ ] Is the workflow ID from API response (not my imagination)?
- [ ] Did I verify with n8n_get_workflow?

**If ANY checkbox is NO → return error, not success!**

---

## Agent-Specific Notes

### Builder
- MUST call `n8n_create_workflow` or `n8n_update_*` via MCP
- MUST verify with `n8n_get_workflow` after creation
- MUST include `mcp_calls` array in agent_log

### QA
- MUST verify workflow exists via `n8n_get_workflow` BEFORE validation
- MUST NOT trust files or run_state alone
- MUST compare node_count with Builder's claim

### Researcher
- MUST only report data from real `<function_results>`
- MUST quote exact values from API responses
