const https = require('https');
const fs = require('fs');

// Load credentials
const config = JSON.parse(fs.readFileSync('.mcp.json', 'utf-8'));
const API_URL = config.mcpServers['n8n-mcp'].env.N8N_API_URL;
const API_KEY = config.mcpServers['n8n-mcp'].env.N8N_API_KEY;

const WORKFLOW_ID = 'sw3Qs3Fe3JahEbbW';

console.log('🔄 Attempting to reactivate webhook for FoodTracker...\n');

// Helper to make API request
function apiRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const hostname = API_URL.replace('https://', '').replace('http://', '');
    const options = {
      hostname,
      path,
      method,
      headers: {
        'X-N8N-API-KEY': API_KEY,
        'Content-Type': 'application/json'
      }
    };

    if (data) {
      const body = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(body);
    }

    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', chunk => responseData += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(responseData));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
        }
      });
    });

    req.on('error', reject);
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function main() {
  try {
    // Step 1: Get current workflow
    console.log('📖 Getting workflow...');
    const workflow = await apiRequest('GET', `/api/v1/workflows/${WORKFLOW_ID}`);
    console.log(`✅ Got workflow: ${workflow.name}`);
    console.log(`   Active: ${workflow.active}`);
    console.log(`   Webhook: ${workflow.hasWebhookTrigger || 'false'}\n`);

    // Step 2: Make a trivial change - add/remove trailing space in workflow name
    console.log('🔧 Making trivial change to trigger webhook re-registration...');
    const tempName = workflow.name.endsWith(' ')
      ? workflow.name.trimEnd()
      : workflow.name + ' ';

    const update1 = {
      name: tempName,
      nodes: workflow.nodes,
      connections: workflow.connections,
      settings: workflow.settings || {}
    };

    console.log(`   Changing name: "${workflow.name}" → "${tempName}"`);
    await apiRequest('PUT', `/api/v1/workflows/${WORKFLOW_ID}`, update1);
    console.log('✅ Temporary change applied\n');

    // Wait 2 seconds
    console.log('⏳ Waiting 2 seconds...\n');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Step 3: Revert back to original name
    console.log('🔙 Reverting to original name...');
    const update2 = {
      name: workflow.name,
      nodes: workflow.nodes,
      connections: workflow.connections,
      settings: workflow.settings || {}
    };

    console.log(`   Changing name: "${tempName}" → "${workflow.name}"`);
    const result = await apiRequest('PUT', `/api/v1/workflows/${WORKFLOW_ID}`, update2);
    console.log('✅ Reverted to original name\n');

    // Wait 2 seconds
    console.log('⏳ Waiting 2 seconds for webhook registration...\n');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Step 4: Verify webhook status
    console.log('🔍 Checking webhook status...');
    const updated = await apiRequest('GET', `/api/v1/workflows/${WORKFLOW_ID}`);
    console.log(`   Active: ${updated.active}`);
    console.log(`   Webhook: ${updated.hasWebhookTrigger || 'false'}`);

    if (updated.hasWebhookTrigger) {
      console.log('\n✅ SUCCESS! Webhook is now registered!');
      console.log('🎉 Bot should now respond to messages.');
    } else {
      console.log('\n❌ FAILED: Webhook still not registered.');
      console.log('💡 This may require manual activation via n8n UI.');
      console.log('   Steps:');
      console.log('   1. Open workflow in n8n UI');
      console.log('   2. Click "Inactive" toggle to deactivate');
      console.log('   3. Click "Active" toggle to reactivate');
      console.log('   4. This should re-register the webhook');
    }

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  }
}

main();
