---
name: n8n-node-configs
description: Частые конфигурации узлов n8n.
---

### Webhook
```
httpMethod: POST
path: /webhook-{{uuid}}
responseMode: onReceived
responseCode: 200
options: { rawBody: false }
```

### HTTP Request
```
method: POST
url: https://api.example.com/v1/resource
sendBody: true
authentication: headerAuth
jsonParameters: true
body: { key: "{{$json.key}}" }
```

### Supabase Insert
```
resource: row
operation: insert
table: your_table
fieldsUi:
  fieldValues:
    - fieldName: name
      fieldValue: "{{$json.name}}"
    - fieldName: email
      fieldValue: "{{$json.email}}"
options:
  returnAll: true
```

### Slack Post Message
```
resource: message
operation: post
channel: #general
text: "{{$json.text}}"
```
