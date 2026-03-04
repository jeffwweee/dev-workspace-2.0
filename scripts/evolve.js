#!/usr/bin/env node
/**
 * evolve.js - Extract patterns from observations and route to memory/candidates
 *
 * Usage: node scripts/evolve.js
 *
 * Reads from: state/learning/observations.jsonl
 * Writes to:
 *   - state/memory/knowledge/patterns.md (high confidence)
 *   - state/memory/knowledge/gotchas.md (high confidence)
 *   - state/learning/candidates/{timestamp}.md (medium confidence)
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..');
const OBSERVATIONS_FILE = path.join(PROJECT_ROOT, 'state/learning/observations.jsonl');
const PATTERNS_FILE = path.join(PROJECT_ROOT, 'state/memory/knowledge/patterns.md');
const GOTCHAS_FILE = path.join(PROJECT_ROOT, 'state/memory/knowledge/gotchas.md');
const CANDIDATES_DIR = path.join(PROJECT_ROOT, 'state/learning/candidates');

// Pattern detection rules
const DETECTION_RULES = [
  {
    type: 'error_resolution',
    signals: ['error', 'failed', 'fix', 'resolved', 'solved'],
    confidence: 0.8,
    target: 'gotchas'
  },
  {
    type: 'code_pattern',
    signals: ['pattern', 'reuse', 'extracted', 'refactored'],
    confidence: 0.7,
    target: 'patterns'
  },
  {
    type: 'decision',
    signals: ['decided', 'chose', 'selected', 'went with'],
    confidence: 0.6,
    target: 'patterns'
  },
  {
    type: 'gotcha',
    signals: ['avoid', 'dont', "don't", 'issue', 'problem', 'warning'],
    confidence: 0.6,
    target: 'gotchas'
  },
  {
    type: 'user_correction',
    signals: ['actually', 'no,', 'correction', 'instead'],
    confidence: 0.5,
    target: 'candidates'
  }
];

function readObservations() {
  if (!fs.existsSync(OBSERVATIONS_FILE)) {
    return [];
  }

  const content = fs.readFileSync(OBSERVATIONS_FILE, 'utf-8').trim();
  if (!content) {
    return [];
  }

  return content.split('\n')
    .filter(line => line.trim())
    .map(line => {
      try {
        return JSON.parse(line);
      } catch (e) {
        console.error(`Skipping invalid JSON line: ${line.substring(0, 50)}...`);
        return null;
      }
    })
    .filter(obs => obs !== null);
}

function detectPatterns(observations) {
  const detected = [];

  for (const obs of observations) {
    const text = `${obs.prompt} ${obs.result_summary}`.toLowerCase();

    for (const rule of DETECTION_RULES) {
      const matchCount = rule.signals.filter(s => text.includes(s.toLowerCase())).length;

      if (matchCount >= 2) {
        detected.push({
          observation: obs,
          patternType: rule.type,
          confidence: Math.min(rule.confidence + (matchCount - 2) * 0.1, 1.0),
          target: rule.target
        });
      }
    }
  }

  return detected;
}

function routePatterns(patterns) {
  const routed = {
    patterns: [],
    gotchas: [],
    candidates: []
  };

  for (const p of patterns) {
    const entry = {
      source: p.observation.task_id,
      type: p.patternType,
      confidence: p.confidence,
      text: p.observation.result_summary.substring(0, 200)
    };

    if (p.confidence >= 0.8) {
      routed[p.target].push(entry);
    } else if (p.confidence >= 0.5) {
      routed.candidates.push(entry);
    }
  }

  return routed;
}

function updateMemoryFile(filepath, entries, sectionName) {
  let content = '';
  if (fs.existsSync(filepath)) {
    content = fs.readFileSync(filepath, 'utf-8');
  } else {
    content = `# ${sectionName}\n\n${sectionName} discovered during development.\n`;
  }

  const timestamp = new Date().toISOString().split('T')[0];
  let newSection = `\n\n## Auto-extracted ${timestamp}\n\n`;

  for (const entry of entries) {
    newSection += `- **${entry.type}** (confidence: ${entry.confidence.toFixed(2)})\n  ${entry.text}\n  Source: ${entry.source}\n\n`;
  }

  content += newSection;
  fs.writeFileSync(filepath, content, 'utf-8');
}

function createCandidatesFile(entries) {
  if (entries.length === 0) return null;

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filepath = path.join(CANDIDATES_DIR, `${timestamp}.md`);

  let content = `# Pattern Candidates\n\nGenerated: ${new Date().toISOString()}\n\n`;

  for (const entry of entries) {
    content += `## ${entry.type}\n\n`;
    content += `**Confidence:** ${entry.confidence.toFixed(2)}\n\n`;
    content += `**Summary:** ${entry.text}\n\n`;
    content += `**Source:** ${entry.source}\n\n`;
    content += `---\n\n`;
  }

  content += `## Review Actions\n\n`;
  content += `- [ ] Promote to patterns.md\n`;
  content += `- [ ] Promote to gotchas.md\n`;
  content += `- [ ] Discard\n`;

  fs.writeFileSync(filepath, content, 'utf-8');
  return filepath;
}

function main() {
  console.log('Reading observations...');
  const observations = readObservations();
  console.log(`Found ${observations.length} observations`);

  if (observations.length === 0) {
    console.log('No observations to process');
    return { patterns: 0, gotchas: 0, candidates: 0 };
  }

  console.log('Detecting patterns...');
  const patterns = detectPatterns(observations);
  console.log(`Detected ${patterns.length} potential patterns`);

  console.log('Routing patterns...');
  const routed = routePatterns(patterns);

  // Update memory files
  if (routed.patterns.length > 0) {
    updateMemoryFile(PATTERNS_FILE, routed.patterns, 'Patterns');
    console.log(`Updated patterns.md with ${routed.patterns.length} entries`);
  }

  if (routed.gotchas.length > 0) {
    updateMemoryFile(GOTCHAS_FILE, routed.gotchas, 'Gotchas');
    console.log(`Updated gotchas.md with ${routed.gotchas.length} entries`);
  }

  // Create candidates file
  if (routed.candidates.length > 0) {
    const candidateFile = createCandidatesFile(routed.candidates);
    console.log(`Created candidate file: ${candidateFile}`);
  }

  return {
    patterns: routed.patterns.length,
    gotchas: routed.gotchas.length,
    candidates: routed.candidates.length
  };
}

// Run if called directly
if (require.main === module) {
  const result = main();
  console.log('\nEvolution complete:');
  console.log(`  Patterns: ${result.patterns}`);
  console.log(`  Gotchas: ${result.gotchas}`);
  console.log(`  Candidates: ${result.candidates}`);
}

module.exports = { readObservations, detectPatterns, routePatterns, main };
