#!/bin/bash
set -e

echo "🔍 System Consistency Checks"
echo "============================"

# Test 1: QA threshold consistency
echo -n "1. QA threshold... "
qa_3=$(grep -c "3 QA fail\|3 cycle" .claude/CLAUDE.md .claude/commands/orch.md 2>/dev/null || echo "0")
qa_7=$(grep -c "7 QA fail\|7 cycle" .claude/CLAUDE.md .claude/commands/orch.md 2>/dev/null || echo "0")
if [ "$qa_3" -eq 0 ] && [ "$qa_7" -gt 0 ]; then
  echo "✅ (standardized to 7)"
else
  echo "❌ (found $qa_3 refs to '3', $qa_7 to '7')"
fi

# Test 2: L-067 shared file exists
echo -n "2. L-067 shared file... "
if [ -f ".claude/agents/shared/L-067-smart-mode-selection.md" ]; then
  echo "✅"
else
  echo "❌ (missing)"
fi

# Test 3: L-067 logic standardized
echo -n "3. L-067 standardization... "
patterns=$(grep -h "node_count > 10" .claude/**/*.md 2>/dev/null | sort -u | wc -l | tr -d ' ')
if [ "$patterns" -le 2 ]; then
  echo "✅ ($patterns unique patterns)"
else
  echo "⚠️ ($patterns variations found)"
fi

# Test 4: IMPACT_ANALYSIS clarity
echo -n "4. IMPACT_ANALYSIS stage... "
refs=$(grep -c "IMPACT_ANALYSIS.*sub-phase\|sub-phase.*IMPACT_ANALYSIS" .claude/commands/orch.md .claude/agents/architect.md 2>/dev/null || echo "0")
if [ "$refs" -ge 2 ]; then
  echo "✅ (clarified in $refs places)"
else
  echo "⚠️ (only $refs clarifications)"
fi

# Test 5: Orchestrator tool restrictions
echo -n "5. Orchestrator restrictions... "
if grep -q "ORCHESTRATOR = PURE ROUTER" .claude/commands/orch.md && grep -q "| Orch |" .claude/CLAUDE.md; then
  echo "✅ (explicit restrictions added)"
else
  echo "❌ (restrictions missing)"
fi

echo "============================"
echo "✅ Consistency check complete"
