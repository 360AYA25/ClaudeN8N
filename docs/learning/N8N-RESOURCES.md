# 🌐 n8n Resources - Where to Search

> **Purpose:** Build workflows faster + Fix problems quicker

---

## 🤖 FOR BOTS: 2 Use Cases

### Use Case 1: Building New Workflow

**Goal:** Find working solution before coding from scratch

**Search order:**

1. **Existing workflow** - Check project workflow.json for node types already used
2. **LEARNINGS.md** - `Grep: {pattern: "keyword"}` → read relevant section
3. **MCP database** - `search_nodes({query: "keyword"})`
4. **Templates** (if MCP fails) - `WebSearch({query: "n8n workflow [task] site:n8n.io/workflows"})`
5. **Docs** - `WebSearch({query: "n8n [node] site:docs.n8n.io"})`

### Use Case 2: Troubleshooting/Fixing Problems

**Goal:** Find solution for error or bug

**Search order:**

1. **LEARNINGS.md** - `Grep: {pattern: "error message"}` → check documented solutions
2. **Community Forum** - `WebSearch({query: "n8n [error] site:community.n8n.io"})`
3. **GitHub Issues** - `WebSearch({query: "n8n [bug] site:github.com/n8n-io/n8n"})`

**Rule:** If MCP fails after 2 tries → use WebSearch immediately

---

## 📚 Resources List

### 🏢 Official Resources

#### 1. Official Documentation
- **URL:** https://docs.n8n.io/
- **Use for:** Node parameters, API reference, official guides
- **Search:** `WebSearch({query: "n8n [node-name] site:docs.n8n.io"})`
- **Key pages:**
  - Supabase node: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.supabase/
  - AI Agent Tools: https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/tools-agent/
  - LangChain overview: https://docs.n8n.io/advanced-ai/langchain/overview/

#### 2. Template Library (6,814 workflows)
- **URL:** https://n8n.io/workflows/
- **Use for:** Copy working solutions, examples, inspiration
- **Search:** `WebSearch({query: "n8n workflow [task] site:n8n.io/workflows"})`
- **Examples:**
  - #2621: AI Agent + Supabase Storage
  - #2395: Supabase CRUD operations
  - #5993: RAG Bot (Gemini + Supabase)
- **Browse by:**
  - Categories (AI, Database, CRM, etc.)
  - Nodes (Supabase, OpenAI, HTTP Request)
  - Use cases (automation, integration, analysis)

#### 3. n8n Blog
- **URL:** https://blog.n8n.io/
- **Use for:** Tutorials, use cases, best practices
- **Content:** Step-by-step guides with code examples

#### 4. Supabase Integration Hub
- **URL:** https://n8n.io/integrations/supabase/
- **Use for:** Supabase-specific workflows (1000+ examples)
- **Search:** Filter by Supabase + AI, Database, Storage

---

### 👥 Community Resources

#### 5. Community Forum
- **URL:** https://community.n8n.io/
- **Use for:** Troubleshooting, workarounds, discussions
- **Search:** `WebSearch({query: "n8n [problem] site:community.n8n.io"})`
- **Key sections:**
  - Questions - search for solutions
  - Tips & Tricks - best practices
  - Built with n8n - real-world examples

#### 6. Discord Server (60,950+ members)
- **URL:** https://discord.com/invite/n8n
- **Use for:** Real-time help, quick answers
- **Key channels:**
  - #help-workflows - workflow troubleshooting
  - #ai-integrations - AI Agent discussions
  - #databases - Supabase, PostgreSQL help

#### 7. GitHub Repository
- **Main repo:** https://github.com/n8n-io/n8n
- **Issues:** https://github.com/n8n-io/n8n/issues
- **Docs repo:** https://github.com/n8n-io/n8n-docs
- **Use for:** Bugs, feature requests, undocumented nodes
- **Search:** `WebSearch({query: "n8n [issue] site:github.com/n8n-io/n8n"})`

---

### 📦 Workflow Collections

#### 8. awesome-n8n (Curated List)
- **URL:** https://github.com/restyler/awesome-n8n
- **Use for:** Curated resources: community nodes, tutorials, examples
- **Content:** Best community contributions

#### 9. n8n-workflows Collection (4,343 workflows)
- **URL:** https://github.com/Zie619/n8n-workflows
- **Use for:** JSON workflow files organized by integration
- **Content:** Community workflows from forum, blogs, tutorials

---

### 📚 Learning Materials

#### 10. YouTube
- **Official n8n channel:** https://www.youtube.com/@n8n-io
- **Use for:** Video tutorials, live streams
- **Search:** "n8n [topic] tutorial"

#### 11. Medium / DEV Community
- **Search:** "n8n workflow tutorial"
- **Example:** [Building RAG AI Agent with n8n, Ollama, and Supabase](https://medium.com/@abhishekarya1/building-a-rag-ai-agent-with-n8n-ollama-and-supabase-9f886fb5c661)
- **Use for:** Community tutorials, deep dives

---

## ⚡ Quick Reference

### Common Node Types (not in MCP)

- **Supabase Tool** - `n8n-nodes-base.supabaseTool` (AI Tool version)
- **AI Tool connections** - Use port `ai_tool`, NOT `main`
- **HTTP Request Tool** - `@n8n/n8n-nodes-langchain.toolHttpRequest` (for AI Agent)

### Common Problems & Solutions

**Problem: Node type not found in MCP**
- → Search templates: `WebSearch({query: "n8n workflow [node-name] site:n8n.io/workflows"})`
- → Check GitHub: `WebSearch({query: "n8n [node-name] site:github.com/n8n-io/n8n"})`

**Problem: Error in workflow execution**
- → Check LEARNINGS.md first (documented solutions)
- → Search community: `WebSearch({query: "n8n [error-message] site:community.n8n.io"})`

**Problem: Node parameters unclear**
- → Search docs: `WebSearch({query: "n8n [node-name] documentation site:docs.n8n.io"})`

**Problem: Need working example**
- → Templates library: `WebSearch({query: "n8n workflow [use-case] site:n8n.io/workflows"})`
- → GitHub workflows: Check awesome-n8n or n8n-workflows repo

---

## 🎯 Decision Tree

### Building Workflow?

```
START
  ↓
Check templates (n8n.io/workflows)
  ↓
Found? → Copy & adapt → DONE
  ↓
Not found
  ↓
Check docs (docs.n8n.io)
  ↓
Build from scratch → DONE
```

### Fixing Problem?

```
START
  ↓
Check LEARNINGS.md
  ↓
Solution documented? → Apply → DONE
  ↓
Not found
  ↓
Search community/GitHub
  ↓
Found workaround? → Apply → Add to LEARNINGS.md → DONE
  ↓
Not found
  ↓
Ask in Discord #help-workflows → DONE
```

---

## 🔍 Search Cheat Sheet

**Template search:**
```
WebSearch({query: "n8n workflow [task] site:n8n.io/workflows"})
```

**Documentation search:**
```
WebSearch({query: "n8n [node-name] site:docs.n8n.io"})
```

**Community troubleshooting:**
```
WebSearch({query: "n8n [error-message] site:community.n8n.io"})
```

**GitHub issues:**
```
WebSearch({query: "n8n [bug-description] site:github.com/n8n-io/n8n"})
```

**Integration examples:**
```
WebSearch({query: "n8n [service] integration site:n8n.io/workflows"})
```

---

**Last Updated:** 2025-11-11
**Total Resources:** 11 official + community sources
**Template Count:** 6,814+ workflows
