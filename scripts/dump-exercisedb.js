#!/usr/bin/env node
/**
 * Dump ExerciseDB data to local files.
 * Usage: node scripts/dump-exercisedb.js
 *
 * Strategy: download full exercise catalog first, then match locally (no rate limit issues)
 * - Downloads GIFs to exercises/gifs/{dataId}.gif
 * - Generates exercises/data.json with metadata
 * - Idempotent: skips downloads that already exist
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const API_BASE = 'https://exercisedb-api.vercel.app/api/v1/exercises';
const GIFS_DIR = path.join(__dirname, '..', 'exercises', 'gifs');
const DATA_FILE = path.join(__dirname, '..', 'exercises', 'data.json');
const CATALOG_CACHE = path.join(__dirname, 'catalog-cache.json');

// Mapping: data-id -> { ptName, search terms, preferTerms (words that must appear) }
const EXERCISES = {
  'b1': { ptName: 'Remada Aberta Curvada', search: 'barbell bent over row', must: ['barbell','bent','row'] },
  'b2': { ptName: 'Crucifixo Inclinado', search: 'dumbbell incline fly', must: ['dumbbell','incline','fly'] },
  'b3': { ptName: 'Remada Fechada Triangulo', search: 'cable seated row', must: ['cable','seated','row'] },
  'b4': { ptName: 'Crucifixo Inverso', search: 'dumbbell reverse fly', must: ['reverse','fly'] },
  'b5': { ptName: 'Face Pull', search: 'cable standing cross-over high reverse fly', must: ['reverse','fly','high'] },
  'b6': { ptName: 'Triceps Corda', search: 'cable pushdown', must: ['cable','pushdown'] },
  'b7': { ptName: 'Supino Reto Halteres', search: 'dumbbell bench press', must: ['dumbbell','bench','press'] },
  'b8': { ptName: 'Biceps Barra W', search: 'ez barbell curl', must: ['curl'] },
  'p1': { ptName: 'Isometria Abducao Parede', search: 'hip abduction', must: ['hip','abduction'] },
  'p2': { ptName: 'Ponte Bipodal', search: 'low glute bridge on floor', must: ['glute','bridge','floor'] },
  'p3': { ptName: 'Agachamento Espanhol', search: 'squat to overhead reach', must: ['squat','overhead'] },
  'p4': { ptName: 'Afundo c/ Flexao Tronco', search: 'dumbbell lunge', must: ['lunge'] },
  'p5': { ptName: 'Cadeira Flexora', search: 'leg curl', must: ['leg','curl'] },
  'p6': { ptName: 'Panturrilha no Step', search: 'standing calf raise', must: ['calf','raise'] },
  'p7': { ptName: 'Cadeira Solear', search: 'seated calf raise', must: ['seated','calf'] },
  'm1-1': { ptName: 'Cat-Cow', search: 'upper back stretch', must: ['upper','back','stretch'] },
  'm1-2': { ptName: "World's Greatest Stretch", search: 'lunge with twist', must: ['lunge','twist'] },
  'm1-3': { ptName: '90/90 Hip Switch', search: 'hip internal rotation', must: ['hip','rotation'] },
  'm1-4': { ptName: 'Toracica Quadrupedia', search: 'exercise ball back extension with rotation', must: ['rotation','extension'] },
  'm1-5': { ptName: 'Bretzel Stretch', search: 'side lying floor stretch', must: ['side','lying','floor','stretch'] },
  'm2-1': { ptName: 'Shoulder CARs', search: 'wrist circles', must: ['circles'] },
  'm2-2': { ptName: 'Hip CARs', search: 'circles knee stretch', must: ['circles','knee'] },
  'm2-3': { ptName: 'Scorpion Stretch', search: 'exercise ball one leg prone lower body rotation', must: ['prone','rotation'] },
  'm2-4': { ptName: 'Deep Squat Hold', search: 'squat to overhead reach', must: ['squat','reach'] },
  'm2-5': { ptName: 'Pigeon Stretch', search: 'assisted side lying adductor stretch', must: ['adductor','stretch'] },
  'm3-1': { ptName: 'Inchworm', search: 'inchworm', must: ['inchworm'] },
  'm3-2': { ptName: 'Spiderman c/ Rotacao', search: 'squat to overhead reach with twist', must: ['squat','twist'] },
  'm3-3': { ptName: 'Cossack Squat', search: 'cossack squat', must: ['cossack'] },
  'm3-4': { ptName: 'Wall Slides', search: 'push-up (wall)', must: ['push-up','wall'] },
  'm3-5': { ptName: "Child's Pose c/ Rotacao", search: 'upper back stretch', must: ['upper','back','stretch'] },
};

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function httpsGet(url) {
  return new Promise((resolve, reject) => {
    const makeRequest = (reqUrl, redirectCount) => {
      if (redirectCount > 5) return reject(new Error('Too many redirects'));
      https.get(reqUrl, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          return makeRequest(res.headers.location, redirectCount + 1);
        }
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => resolve({ status: res.statusCode, body: data }));
      }).on('error', reject);
    };
    makeRequest(url, 0);
  });
}

function downloadFile(url, destPath) {
  return new Promise((resolve, reject) => {
    const makeRequest = (reqUrl, redirectCount) => {
      if (redirectCount > 5) return reject(new Error('Too many redirects'));
      const parsedUrl = new URL(reqUrl);
      const mod = parsedUrl.protocol === 'https:' ? https : require('http');
      mod.get(reqUrl, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          return makeRequest(res.headers.location, redirectCount + 1);
        }
        if (res.statusCode !== 200) {
          return reject(new Error('HTTP ' + res.statusCode));
        }
        const ws = fs.createWriteStream(destPath);
        res.pipe(ws);
        ws.on('finish', () => ws.close(resolve));
        ws.on('error', reject);
      }).on('error', reject);
    };
    makeRequest(url, 0);
  });
}

async function downloadCatalog() {
  // Check cache first
  if (fs.existsSync(CATALOG_CACHE)) {
    console.log('Using cached catalog...');
    return JSON.parse(fs.readFileSync(CATALOG_CACHE, 'utf8'));
  }

  console.log('Downloading full exercise catalog...');
  const allExercises = [];
  let offset = 0;
  const limit = 100;

  while (true) {
    const url = `${API_BASE}?limit=${limit}&offset=${offset}`;
    process.stdout.write(`  Fetching offset ${offset}...`);

    const resp = await httpsGet(url);
    if (resp.status === 429) {
      console.log(' rate limited, waiting 10s...');
      await sleep(10000);
      continue;
    }
    if (resp.status !== 200) {
      console.log(' ERROR: HTTP ' + resp.status);
      break;
    }

    const json = JSON.parse(resp.body);
    const exercises = json.data || [];
    allExercises.push(...exercises);
    console.log(` got ${exercises.length} (total: ${allExercises.length})`);

    if (exercises.length < limit) break;
    offset += limit;
    await sleep(2000);
  }

  // Cache locally
  fs.writeFileSync(CATALOG_CACHE, JSON.stringify(allExercises, null, 2));
  console.log(`Catalog: ${allExercises.length} exercises cached\n`);
  return allExercises;
}

function findBestMatch(catalog, search, mustWords) {
  const lower = search.toLowerCase();
  const words = lower.split(/\s+/);

  // Score each exercise
  let best = null;
  let bestScore = 0;

  for (const ex of catalog) {
    const name = ex.name.toLowerCase();

    // Exact match -> perfect score
    if (name === lower) return { ex, score: 100 };

    // Check must-words (all must be present)
    if (mustWords && mustWords.length > 0) {
      const hasMust = mustWords.every(w => name.includes(w));
      if (!hasMust) continue;
    }

    // Score by word overlap
    let score = 0;
    for (const w of words) {
      if (name.includes(w)) score += 10;
    }

    // Bonus: shorter names (more specific) score higher
    score -= name.split(/\s+/).length;

    // Bonus: name starts with search
    if (name.startsWith(lower)) score += 20;

    if (score > bestScore) {
      bestScore = score;
      best = ex;
    }
  }

  return best ? { ex: best, score: bestScore } : null;
}

async function main() {
  fs.mkdirSync(GIFS_DIR, { recursive: true });

  const catalog = await downloadCatalog();

  const result = {};
  const ids = Object.keys(EXERCISES);
  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < ids.length; i++) {
    const id = ids[i];
    const { ptName, search, must } = EXERCISES[id];
    const gifPath = path.join(GIFS_DIR, id + '.gif');

    process.stdout.write(`[${i + 1}/${ids.length}] ${id} "${ptName}" -> "${search}" ... `);

    // Find in local catalog
    const match = findBestMatch(catalog, search, must);

    if (!match) {
      console.log('NO MATCH');
      result[id] = makeManualEntry(id, ptName, search);
      failCount++;
      continue;
    }

    const ex = match.ex;
    const gifUrl = ex.gifUrl;

    // Download GIF if not already present
    if (fs.existsSync(gifPath)) {
      const size = fs.statSync(gifPath).size;
      process.stdout.write(`"${ex.name}" `);
      console.log(`EXISTS (${(size / 1024).toFixed(0)} KB)`);
    } else if (gifUrl) {
      try {
        await downloadFile(gifUrl, gifPath);
        const size = fs.statSync(gifPath).size;
        console.log(`"${ex.name}" OK (${(size / 1024).toFixed(0)} KB)`);
        await sleep(500); // Small delay between downloads
      } catch (err) {
        console.log(`"${ex.name}" DOWNLOAD ERROR: ${err.message}`);
      }
    } else {
      console.log(`"${ex.name}" NO GIF URL`);
    }

    result[id] = {
      dataId: id,
      ptName,
      name: ex.name || search,
      bodyPart: (ex.bodyParts || [])[0] || '',
      equipment: (ex.equipments || [])[0] || '',
      target: (ex.targetMuscles || [])[0] || '',
      secondaryMuscles: ex.secondaryMuscles || [],
      instructions: (ex.instructions || []).map(s => s.replace(/^Step:\d+\s*/, '')),
      gifFile: fs.existsSync(gifPath) ? id + '.gif' : null,
      source: 'exercisedb',
    };
    successCount++;
  }

  // Write data.json
  fs.writeFileSync(DATA_FILE, JSON.stringify(result, null, 2));
  console.log(`\nDone! ${successCount} matched, ${failCount} failed.`);
  console.log('Data saved to: ' + DATA_FILE);

  // List GIF files
  const gifs = fs.readdirSync(GIFS_DIR).filter(f => f.endsWith('.gif'));
  console.log(`GIFs downloaded: ${gifs.length}`);
  if (gifs.length > 0) {
    const totalSize = gifs.reduce((sum, f) => sum + fs.statSync(path.join(GIFS_DIR, f)).size, 0);
    console.log(`Total size: ${(totalSize / 1024 / 1024).toFixed(1)} MB`);
  }

  // Show failures
  const failures = Object.entries(result).filter(([_, v]) => v.source === 'manual');
  if (failures.length > 0) {
    console.log('\nFailed exercises:');
    failures.forEach(([id, v]) => console.log(`  ${id}: ${v.ptName}`));
  }
}

function makeManualEntry(id, ptName, search) {
  return {
    dataId: id,
    ptName,
    name: search,
    bodyPart: '',
    equipment: '',
    target: '',
    secondaryMuscles: [],
    instructions: [],
    gifFile: null,
    source: 'manual',
  };
}

main().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});
