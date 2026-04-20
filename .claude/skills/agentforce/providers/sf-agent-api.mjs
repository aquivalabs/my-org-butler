import { execSync } from 'child_process';

let cachedAuth = null;
const sessionCache = new Map();

function getAuth() {
  if (cachedAuth) return cachedAuth;

  const result = JSON.parse(
    execSync('sf org display --json', { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] })
  );

  cachedAuth = {
    instanceUrl: result.result.instanceUrl,
    accessToken: result.result.accessToken,
  };
  return cachedAuth;
}

async function sendMessage(instanceUrl, accessToken, agentName, apiVersion, userMessage, sessionId) {
  const input = { userMessage };
  if (sessionId) input.sessionId = sessionId;

  // Retry on transient Salesforce agent API failures (HTTP 5xx or known flaky errors)
  const MAX_ATTEMPTS = 3;
  let lastError = null;
  let data = null;

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const res = await fetch(
      `${instanceUrl}/services/data/${apiVersion}/actions/custom/generateAiAgentResponse/${agentName}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ inputs: [input] }),
      }
    );

    const bodyText = await res.text();
    const isFlakyServerError = /InvalidPlannerConfigException|MISSING_RECORD|response code 5\d\d/.test(bodyText);

    if (!res.ok) {
      lastError = `HTTP ${res.status}: ${bodyText}`;
      if (res.status >= 500 || isFlakyServerError) {
        if (attempt < MAX_ATTEMPTS) { await new Promise(r => setTimeout(r, 1500 * attempt)); continue; }
      }
      throw new Error(lastError);
    }

    data = JSON.parse(bodyText);
    const checkResult = data[0];
    if (!checkResult.isSuccess && isFlakyServerError && attempt < MAX_ATTEMPTS) {
      await new Promise(r => setTimeout(r, 1500 * attempt));
      continue;
    }
    break;
  }

  const actionResult = data[0];

  if (!actionResult.isSuccess) {
    return { success: false, error: JSON.stringify(actionResult.errors) };
  }

  let text = actionResult.outputValues?.agentResponse;
  try {
    const parsed = JSON.parse(text);
    text = parsed.value || text;
  } catch {
    // Use raw text if not JSON
  }

  return {
    success: true,
    text,
    sessionId: actionResult.outputValues?.sessionId,
  };
}

export default class SfAgentApiProvider {
  id() {
    return 'sf-agent-api';
  }

  async callApi(prompt, context) {
    const { instanceUrl, accessToken } = getAuth();
    const vars = context.vars || {};

    const agentName = process.env.AGENT_NAME || vars.agentName;
    const apiVersion = process.env.API_VERSION || vars.apiVersion || 'v65.0';

    if (!agentName) {
      throw new Error('AGENT_NAME must be set via environment variable or test var');
    }

    // Multi-turn: reuse sessionId from previous turns in the same conversation
    const conversationId = vars.conversationId || context.metadata?.conversationId;
    const sessionId = conversationId ? sessionCache.get(conversationId) : null;

    const userMessage = prompt || vars.utterance;
    const response = await sendMessage(instanceUrl, accessToken, agentName, apiVersion, userMessage, sessionId);

    // Cache sessionId for the next turn in this conversation
    if (conversationId && response.sessionId) {
      sessionCache.set(conversationId, response.sessionId);
    }

    return { output: response };
  }
}
