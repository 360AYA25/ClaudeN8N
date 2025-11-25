---
name: n8n-audit
description: Log analysis patterns, root cause templates, and learning capture protocols.
---

# N8N Audit

## Audit Protocol

### Step 1: Gather Evidence
```
1. Read memory/run_state.json - full current state
2. Read memory/history.jsonl - all historical events
3. Extract agent_log entries - who did what
4. Extract _meta.fix_attempts from each node - what was tried
5. Get workflow versions (if available) - changes over time
6. Get execution logs - runtime errors
```

### Step 2: Build Timeline
```json
{
  "timeline": [
    { "ts": "...", "agent": "researcher", "action": "search_nodes", "result": "found 3" },
    { "ts": "...", "agent": "builder", "action": "create_workflow", "result": "success" },
    { "ts": "...", "agent": "qa", "action": "validate", "result": "failed: missing param" },
    { "ts": "...", "agent": "builder", "action": "fix_node", "result": "success" },
    { "ts": "...", "agent": "qa", "action": "validate", "result": "failed: same error" }
  ]
}
```

### Step 3: Identify Patterns
- Same error repeating? → Fix not applied correctly
- New errors after fix? → Regression introduced
- Agent looping? → Wrong fix approach
- Escalation triggered? → Complexity underestimated

### Step 4: Determine Root Cause

## Failure Source Classification

### Implementation Failure
Builder made incorrect change or wrong approach.

**Indicators:**
- Error persists after fix attempt
- Regression introduced by fix
- Syntax/parameter errors in output

**Recommendation:** Builder retry with different approach

### Analysis Failure
Researcher provided wrong info or missed pattern.

**Indicators:**
- Wrong template/node recommended
- Missing pattern not found in search
- Excluded fix was actually correct

**Recommendation:** Researcher retry with broader search

### Unknown Failure
Cannot determine cause from available data.

**Indicators:**
- External service error
- Credential issue
- n8n platform bug
- Incomplete evidence

**Recommendation:** Escalate to user (L4)

## Root Cause Template

```json
{
  "root_cause": {
    "what": "Brief description of the failure",
    "why": "Deep analysis of why it happened",
    "evidence": [
      "agent_log entry showing X",
      "execution log showing Y",
      "_meta.fix_attempts showing Z"
    ],
    "chain": [
      "1. Initial error occurred",
      "2. Fix attempt A applied",
      "3. Fix A caused regression B",
      "4. Cycle repeated 3 times"
    ]
  }
}
```

## Learning Capture Format

When proposing new learning for memory/learnings.md:

```json
{
  "proposed_learnings": [{
    "pattern_id": "next_available",
    "title": "Short descriptive title",
    "description": "What we learned and why it matters",
    "category": "n8n Workflows|Supabase|HTTP|etc",
    "example": {
      "wrong": "Code showing wrong approach",
      "correct": "Code showing correct approach"
    },
    "source": "This incident - workflow X, date Y",
    "keywords": ["keyword1", "keyword2"]
  }]
}
```

## Recommendation Template

```json
{
  "recommendation": {
    "assignee": "researcher|builder|user",
    "action": "Specific action to take",
    "risk": "low|medium|high",
    "rationale": "Why this recommendation",
    "alternatives": ["Option B if this fails"]
  }
}
```

## Audit Output Format

```json
{
  "audit_id": "uuid",
  "workflow_id": "...",
  "timestamp": "...",
  "timeline": [...],
  "root_cause": {...},
  "failure_source": "implementation|analysis|unknown",
  "cycles_analyzed": 3,
  "regressions_found": 1,
  "recommendation": {...},
  "proposed_learnings": [...],
  "confidence": "high|medium|low"
}
```

## Analyst Hard Rules

1. **NEVER** mutate workflows
2. **NEVER** delegate to other agents
3. **NEVER** activate or execute
4. **ONLY** read and analyze
5. **CAN WRITE** only to memory/learnings.md
6. **ALWAYS** provide evidence for conclusions

## Red Flags to Watch

- **Loop detection:** Same fix applied 3+ times
- **Regression chain:** Fix A breaks B, fix B breaks C
- **Evidence gaps:** Missing logs for key actions
- **Silent failures:** No error but wrong result
- **Credential issues:** Auth errors across agents
