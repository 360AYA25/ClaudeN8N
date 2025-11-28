const https = require('https');
const fs = require('fs');

// Load credentials
const config = JSON.parse(fs.readFileSync('.mcp.json', 'utf-8'));
const API_URL = config.mcpServers['n8n-mcp'].env.N8N_API_URL;
const API_KEY = config.mcpServers['n8n-mcp'].env.N8N_API_KEY;

const WORKFLOW_ID = 'sw3Qs3Fe3JahEbbW';
const TARGET_NODE_ID = '18d2242f-51eb-48c9-8d1c-1fef81ce9974';

console.log('🔧 Fixing FoodTracker workflow model name...\n');

// Step 1: Get workflow
const getOptions = {
  hostname: API_URL.replace('https://', '').replace('http://', ''),
  path: `/api/v1/workflows/${WORKFLOW_ID}`,
  method: 'GET',
  headers: {
    'X-N8N-API-KEY': API_KEY
  }
};

const req = https.request(getOptions, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const workflow = JSON.parse(data);
    console.log(`✅ Got workflow: ${workflow.name} (${workflow.nodes.length} nodes)\n`);

    // Step 2: Find and fix node
    const node = workflow.nodes.find(n => n.id === TARGET_NODE_ID);
    if (!node) {
      console.error(`❌ Node ${TARGET_NODE_ID} not found!`);
      return;
    }

    console.log(`📍 Found node: ${node.name}`);
    console.log(`   Old model: ${node.parameters.model.value}`);

    // Fix the model name
    node.parameters.model.value = 'gpt-4o-mini';
    console.log(`   New model: ${node.parameters.model.value}\n`);

    // Step 3: Create clean workflow (only: name, nodes, connections, settings)
    const cleanWorkflow = {
      name: workflow.name,
      nodes: workflow.nodes,
      connections: workflow.connections,
      settings: workflow.settings || {}
    };

    // Step 4: Update workflow
    const updateData = JSON.stringify(cleanWorkflow);
    const updateOptions = {
      hostname: API_URL.replace('https://', '').replace('http://', ''),
      path: `/api/v1/workflows/${WORKFLOW_ID}`,
      method: 'PUT',
      headers: {
        'X-N8N-API-KEY': API_KEY,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(updateData)
      }
    };

    const updateReq = https.request(updateOptions, (updateRes) => {
      let updateData = '';
      updateRes.on('data', chunk => updateData += chunk);
      updateRes.on('end', () => {
        if (updateRes.statusCode === 200) {
          const result = JSON.parse(updateData);
          console.log('✅ Workflow updated successfully!');
          console.log(`   Version ID: ${result.versionId || 'N/A'}\n`);
          console.log('🎉 Model fixed: gpt-4.1-mini → gpt-4o-mini');
        } else {
          console.error(`❌ Update failed (${updateRes.statusCode}):`);
          console.error(updateData);
        }
      });
    });

    updateReq.on('error', (e) => {
      console.error(`❌ Update error: ${e.message}`);
    });

    updateReq.write(updateData);
    updateReq.end();
  });
});

req.on('error', (e) => {
  console.error(`❌ Get error: ${e.message}`);
});

req.end();
