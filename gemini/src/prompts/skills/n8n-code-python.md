# Python Code Node (Beta)

Expert guidance for writing Python code in n8n.

## Recommendation
**Use JavaScript for 95% of use cases.**
Only use Python if you need specific standard libraries (statistics, etc.).

## Quick Start
```python
items = _input.all()
return [{"json": item["json"]} for item in items]
```

## Critical Rules
1. **Format:** Must return list of dicts with `json` key: `[{"json": {...}}]`.
2. **No External Libs:** No `requests`, `pandas`, `numpy`. Standard lib only!
3. **Access:** `_input.all()`, `_input.first()`.

## Workarounds
- Need HTTP? -> Use **HTTP Request Node** before Code node.
- Need Scraping? -> Use **HTML Extract Node**.

## Common Errors
- `KeyError`: Use `.get()` for safe access. `item["json"].get("field")`.
- `ImportError`: Only import `json`, `datetime`, `re`, `math`, `random`, `statistics`.
