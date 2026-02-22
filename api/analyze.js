export const config = {
  runtime: 'edge',
};

const ANTHROPIC_API_KEY = (process.env.ANTHROPIC_API_KEY || '').trim();

export default async function handler(req) {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const body = await req.json();

    // Support multi-turn: { messages, system } or legacy { prompt }
    let messages;
    let system;

    if (body.messages && Array.isArray(body.messages)) {
      messages = body.messages;
      system = body.system || undefined;
    } else if (body.prompt) {
      messages = [{ role: 'user', content: body.prompt }];
    } else {
      return new Response(JSON.stringify({ error: 'Missing messages or prompt' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const requestBody = {
      model: 'claude-sonnet-4-5-20250929',
      max_tokens: 4096,
      messages,
    };

    if (system) {
      requestBody.system = system;
    }

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const error = await response.text();
      return new Response(JSON.stringify({ error, _debug: { keyLen: ANTHROPIC_API_KEY.length, keyEnd: ANTHROPIC_API_KEY.slice(-4), status: response.status } }), {
        status: response.status,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      });
    }

    const data = await response.json();
    const content = data.content?.[0]?.text || 'Sem resposta';

    return new Response(JSON.stringify({ content }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
