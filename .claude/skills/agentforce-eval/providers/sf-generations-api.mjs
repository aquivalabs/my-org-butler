import { execSync } from 'child_process';

let cachedAuth = null;

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

const RESERVED_VARS = new Set(['promptTemplateName', 'sobjectInputs', 'apiVersion']);

function buildInputParams(vars) {
  const sobjectInputs = vars.sobjectInputs || {};
  const valueMap = {};

  for (const [key, value] of Object.entries(vars)) {
    if (RESERVED_VARS.has(key)) continue;

    if (sobjectInputs[key]) {
      valueMap[key] = { value: { id: value } };
    } else {
      valueMap[key] = { value: String(value) };
    }
  }
  return { valueMap };
}

export default class SfGenerationsApiProvider {
  id() {
    return 'sf-generations-api';
  }

  async callApi(prompt, context) {
    const { instanceUrl, accessToken } = getAuth();
    const vars = context.vars || {};

    const templateName = vars.promptTemplateName;
    const apiVersion = process.env.API_VERSION || vars.apiVersion || 'v65.0';

    if (!templateName) {
      throw new Error('promptTemplateName must be set as a test var');
    }

    const inputParams = buildInputParams(vars);

    const startTime = Date.now();

    const res = await fetch(
      `${instanceUrl}/services/data/${apiVersion}/einstein/prompt-templates/${templateName}/generations`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ inputParams, isPreview: false }),
      }
    );

    const latencyMs = Date.now() - startTime;

    if (!res.ok) {
      const text = await res.text();
      return { output: { success: false, latencyMs, error: `HTTP ${res.status}: ${text}` } };
    }

    const data = await res.json();

    if (data.generationErrors?.length > 0) {
      return {
        output: {
          success: false,
          latencyMs,
          error: JSON.stringify(data.generationErrors),
          promptTemplateName: data.promptTemplateDevName,
        },
      };
    }

    const generation = data.generations?.[0];

    return {
      output: {
        success: true,
        latencyMs,
        text: generation?.text || '',
        promptTemplateName: data.promptTemplateDevName,
        safetyScores: generation?.safetyScoreRepresentation || null,
      },
    };
  }
}
