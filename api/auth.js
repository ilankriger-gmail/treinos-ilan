export const config = {
  runtime: 'edge',
};

const SUPABASE_URL = (process.env.SUPABASE_URL || 'https://nxvwihwpzungfeovkevx.supabase.co').replace(/\\n/g, '').trim();
const SUPABASE_SERVICE_KEY = (process.env.SUPABASE_SERVICE_KEY || '').replace(/\\n/g, '').trim();

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

async function supabaseQuery(path, options = {}) {
  const key = SUPABASE_SERVICE_KEY;
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...options,
    headers: {
      'apikey': key,
      'Authorization': `Bearer ${key}`,
      'Content-Type': 'application/json',
      'Prefer': options.prefer || 'return=representation',
      ...options.headers,
    },
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(text || `Supabase error: ${res.status}`);
  }
  return text ? JSON.parse(text) : null;
}

// PBKDF2 password hashing using Web Crypto API
async function hashPassword(password, salt) {
  const encoder = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    encoder.encode(password),
    'PBKDF2',
    false,
    ['deriveBits']
  );
  const bits = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: encoder.encode(salt),
      iterations: 100000,
      hash: 'SHA-256',
    },
    keyMaterial,
    256
  );
  return Array.from(new Uint8Array(bits))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

function generateToken() {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return Array.from(bytes)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

function generateSalt() {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return Array.from(bytes)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function handleSignup(body) {
  const { email, password, nome } = body;

  if (!email || !password) {
    return jsonResponse({ error: 'Email e senha são obrigatórios' }, 400);
  }

  if (!isValidEmail(email)) {
    return jsonResponse({ error: 'Email inválido' }, 400);
  }

  if (password.length < 6) {
    return jsonResponse({ error: 'Senha deve ter pelo menos 6 caracteres' }, 400);
  }

  // Check if email already exists
  const existing = await supabaseQuery(
    `users?email=eq.${encodeURIComponent(email)}&select=id`,
    { method: 'GET' }
  );

  if (existing && existing.length > 0) {
    return jsonResponse({ error: 'Este email já está cadastrado' }, 409);
  }

  // Hash password
  const salt = generateSalt();
  const passwordHash = await hashPassword(password, salt);

  // Create user
  const users = await supabaseQuery('users', {
    method: 'POST',
    body: JSON.stringify({
      email: email.toLowerCase().trim(),
      password_hash: passwordHash,
      salt,
      nome: nome || null,
    }),
  });

  const user = users[0];

  // Create session
  const token = generateToken();
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(); // 30 days

  await supabaseQuery('user_sessions', {
    method: 'POST',
    body: JSON.stringify({
      user_id: user.id,
      token,
      expires_at: expiresAt,
    }),
  });

  // Update last_login
  await supabaseQuery(`users?id=eq.${user.id}`, {
    method: 'PATCH',
    body: JSON.stringify({ last_login: new Date().toISOString() }),
  });

  return jsonResponse({
    token,
    user: { id: user.id, email: user.email, nome: user.nome },
  });
}

async function handleLogin(body) {
  const { email, password } = body;

  if (!email || !password) {
    return jsonResponse({ error: 'Email e senha são obrigatórios' }, 400);
  }

  // Find user
  const users = await supabaseQuery(
    `users?email=eq.${encodeURIComponent(email.toLowerCase().trim())}&select=*`,
    { method: 'GET' }
  );

  if (!users || users.length === 0) {
    return jsonResponse({ error: 'Email ou senha incorretos' }, 401);
  }

  const user = users[0];

  // Verify password
  const passwordHash = await hashPassword(password, user.salt);

  if (passwordHash !== user.password_hash) {
    return jsonResponse({ error: 'Email ou senha incorretos' }, 401);
  }

  // Create session
  const token = generateToken();
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(); // 30 days

  await supabaseQuery('user_sessions', {
    method: 'POST',
    body: JSON.stringify({
      user_id: user.id,
      token,
      expires_at: expiresAt,
    }),
  });

  // Update last_login
  await supabaseQuery(`users?id=eq.${user.id}`, {
    method: 'PATCH',
    body: JSON.stringify({ last_login: new Date().toISOString() }),
  });

  return jsonResponse({
    token,
    user: { id: user.id, email: user.email, nome: user.nome },
  });
}

async function handleVerify(body) {
  const { token } = body;

  if (!token) {
    return jsonResponse({ error: 'Token não fornecido' }, 400);
  }

  const sessions = await supabaseQuery(
    `user_sessions?token=eq.${encodeURIComponent(token)}&select=*,users(id,email,nome)`,
    { method: 'GET' }
  );

  if (!sessions || sessions.length === 0) {
    return jsonResponse({ error: 'Sessão inválida' }, 401);
  }

  const session = sessions[0];

  // Check expiration
  if (new Date(session.expires_at) < new Date()) {
    // Clean up expired session
    await supabaseQuery(`user_sessions?token=eq.${encodeURIComponent(token)}`, {
      method: 'DELETE',
    });
    return jsonResponse({ error: 'Sessão expirada' }, 401);
  }

  return jsonResponse({
    valid: true,
    user: session.users,
  });
}

async function handleLogout(body) {
  const { token } = body;

  if (!token) {
    return jsonResponse({ error: 'Token não fornecido' }, 400);
  }

  await supabaseQuery(`user_sessions?token=eq.${encodeURIComponent(token)}`, {
    method: 'DELETE',
  });

  return jsonResponse({ success: true });
}

export default async function handler(req) {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const url = new URL(req.url);
  const action = url.searchParams.get('action');

  try {
    const body = await req.json();

    switch (action) {
      case 'signup':
        return await handleSignup(body);
      case 'login':
        return await handleLogin(body);
      case 'verify':
        return await handleVerify(body);
      case 'logout':
        return await handleLogout(body);
      default:
        return jsonResponse({ error: 'Ação inválida' }, 400);
    }
  } catch (error) {
    console.error('Auth error:', error);
    return jsonResponse({ error: 'Erro interno do servidor' }, 500);
  }
}
