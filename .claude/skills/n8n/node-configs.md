---
name: n8n-node-configs
description: Common n8n node configurations and required parameters.
---

# N8N Node Configurations

## Trigger Nodes

### Webhook
```json
{
  "type": "n8n-nodes-base.webhook",
  "parameters": {
    "httpMethod": "POST",
    "path": "/webhook-{{ uuid }}",
    "responseMode": "onReceived",
    "responseCode": 200,
    "options": {
      "rawBody": false
    }
  }
}
```

**Required:** `httpMethod`, `path`, `responseMode`
**Pattern 52:** Always unique path!

### Schedule Trigger
```json
{
  "type": "n8n-nodes-base.scheduleTrigger",
  "parameters": {
    "rule": {
      "interval": [{ "field": "hours", "hoursInterval": 1 }]
    }
  }
}
```

## Data Nodes

### Set (v3.4+)
```json
{
  "type": "n8n-nodes-base.set",
  "typeVersion": 3.4,
  "parameters": {
    "mode": "manual",
    "duplicateItem": false,
    "assignments": {
      "assignments": [
        {
          "id": "uuid",
          "name": "fieldName",
          "value": "={{ $json.inputField }}",
          "type": "string"
        }
      ]
    },
    "includeOtherFields": false,
    "options": {}
  }
}
```

**Critical:** Use `={{ }}` syntax (not `{{ }}`)!
**Pattern 47:** Always set `mode: "manual"`

### Code Node
```json
{
  "type": "n8n-nodes-base.code",
  "parameters": {
    "mode": "runOnceForAllItems",
    "jsCode": "return items.map(item => ({ json: { result: item.json.value } }));"
  }
}
```

## Database Nodes

### Supabase Insert
```json
{
  "type": "n8n-nodes-base.supabase",
  "parameters": {
    "resource": "row",
    "operation": "insert",
    "tableId": "your_table_name",
    "fieldsUi": {
      "fieldValues": [
        { "fieldName": "name", "fieldValue": "={{ $json.name }}" },
        { "fieldName": "email", "fieldValue": "={{ $json.email }}" },
        { "fieldName": "created_at", "fieldValue": "={{ new Date().toISOString() }}" }
      ]
    },
    "options": {
      "returnAll": true
    }
  },
  "credentials": {
    "supabaseApi": { "id": "credential_id", "name": "Supabase" }
  }
}
```

**Pattern 23:** Always use `fieldsUi.fieldValues`!

### Supabase Select
```json
{
  "type": "n8n-nodes-base.supabase",
  "parameters": {
    "resource": "row",
    "operation": "getAll",
    "tableId": "your_table_name",
    "returnAll": true,
    "filters": {
      "conditions": [
        { "keyName": "status", "condition": "eq", "keyValue": "active" }
      ]
    }
  }
}
```

## Communication Nodes

### Slack Post Message
```json
{
  "type": "n8n-nodes-base.slack",
  "parameters": {
    "resource": "message",
    "operation": "post",
    "channel": "#general",
    "text": "={{ $json.message }}",
    "otherOptions": {}
  },
  "credentials": {
    "slackApi": { "id": "credential_id", "name": "Slack" }
  }
}
```

### HTTP Request
```json
{
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "https://api.example.com/endpoint",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpHeaderAuth",
    "sendBody": true,
    "bodyParameters": {
      "parameters": [
        { "name": "key", "value": "={{ $json.value }}" }
      ]
    },
    "options": {
      "timeout": 30000,
      "response": { "response": { "fullResponse": true } }
    }
  }
}
```

**Pattern 47:** Always set `timeout`!

## Logic Nodes

### IF Node
```json
{
  "type": "n8n-nodes-base.if",
  "parameters": {
    "conditions": {
      "options": { "caseSensitive": true, "leftValue": "", "typeValidation": "strict" },
      "conditions": [
        {
          "id": "uuid",
          "leftValue": "={{ $json.status }}",
          "rightValue": "active",
          "operator": { "type": "string", "operation": "equals" }
        }
      ],
      "combinator": "and"
    }
  }
}
```

### Switch Node
```json
{
  "type": "n8n-nodes-base.switch",
  "parameters": {
    "mode": "rules",
    "rules": {
      "rules": [
        {
          "outputKey": "case1",
          "conditions": {
            "conditions": [{ "leftValue": "={{ $json.type }}", "rightValue": "A", "operator": { "operation": "equals" } }]
          }
        }
      ]
    }
  }
}
```

## Error Handling Options

Add to any node for error handling:
```json
{
  "onError": "continueRegularOutput",
  "retryOnFail": true,
  "maxTries": 3,
  "waitBetweenTries": 1000
}
```
