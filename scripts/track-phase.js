#!/usr/bin/env node

/**
 * Phase Tracker Hook
 *
 * Detects workflow skill completion and triggers pre-compact flow.
 * Called as PreToolUse hook on Edit|Write operations.
 *
 * Detection: Parses terminal output for skill exit markers:
 *   <!-- PHASE_COMPLETE: brainstorming -->
 *   <!-- PHASE_COMPLETE: writing-plans -->
 *   <!-- PHASE_COMPLETE: subagent-driven-development -->
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const PROJECT_ID_FILE = path.join(__dirname, '..', 'state/sessions/.project-id.json');
const PHASE_STATE_FILE = path.join(__dirname, '..', 'state/sessions/.phase-state.json');
const TMUX_SESSION = 'cc-pichu:0.0';
const COMPACT_DELAY = 30; // seconds

// Phase markers to detect
const PHASE_MARKERS = {
  'brainstorming': 'planning',
  'writing-plans': 'execution',
  'subagent-driven-development': 'complete'
};

function getProjectId() {
  try {
    const data = fs.readFileSync(PROJECT_ID_FILE, 'utf8');
    return JSON.parse(data);
  } catch {
    return { currentProject: null, chatProjects: {} };
  }
}

function saveProjectId(data) {
  fs.writeFileSync(PROJECT_ID_FILE, JSON.stringify(data, null, 2));
}

function getPhaseState() {
  try {
    const data = fs.readFileSync(PHASE_STATE_FILE, 'utf8');
    return JSON.parse(data);
  } catch {
    return { lastPhase: null, canTrigger: true };
  }
}

function savePhaseState(state) {
  fs.writeFileSync(PHASE_STATE_FILE, JSON.stringify(state, null, 2));
}

function detectPhaseFromTerminal() {
  try {
    // Get recent terminal output from tmux
    const output = execSync(
      `tmux capture-pane -t ${TMUX_SESSION} -p -S -100`,
      { encoding: 'utf8' }
    );

    // Check for phase completion markers
    for (const [phase, nextPhase] of Object.entries(PHASE_MARKERS)) {
      const marker = `<!-- PHASE_COMPLETE: ${phase} -->`;
      if (output.includes(marker)) {
        return { phase, nextPhase, detected: true };
      }
    }

    return { detected: false };
  } catch (error) {
    // Silently fail if tmux not available
    return { detected: false };
  }
}

function generateProjectId(designFile) {
  // Extract date and slug from design file path
  // e.g., "2026-03-04-phase-aware-compact-hook-design.md"
  const match = designFile.match(/(\d{4}-\d{2}-\d{2})-(.+)-design\.md/);
  if (match) {
    return `${match[1]}-${match[2]}`;
  }
  // Fallback: use current date and generic name
  const date = new Date().toISOString().split('T')[0];
  return `${date}-project`;
}

function extractDesignFileFromTerminal() {
  try {
    const output = execSync(
      `tmux capture-pane -t ${TMUX_SESSION} -p -S -50`,
      { encoding: 'utf8' }
    );

    // Look for design file being written
    const match = output.match(/docs\/plans\/(\d{4}-\d{2}-\d{2}-.+)-design\.md/);
    return match ? match[0] : null;
  } catch {
    return null;
  }
}

function triggerPreCompactFlow(phase, nextPhase) {
  try {
    // 1. Save state before compact
    execSync(`node ${path.join(__dirname, 'save-state-before-compact.js')} ${phase} ${nextPhase}`);

    // 2. Trigger delayed compact
    execSync(`${path.join(__dirname, 'trigger-compact.sh')}`);

    // Update phase state to prevent duplicate triggers
    savePhaseState({ lastPhase: phase, canTrigger: false });

    console.error(`\n📦 Phase transition detected: ${phase} → ${nextPhase}`);
    console.error(`   State saved. Compacting in ${COMPACT_DELAY}s...\n`);
  } catch (error) {
    console.error(`Failed to trigger pre-compact flow: ${error.message}`);
  }
}

function main() {
  const phaseState = getPhaseState();

  // Check if we recently triggered (prevent duplicates)
  if (!phaseState.canTrigger) {
    // Reset canTrigger after some time (e.g., 2 minutes)
    // This allows multiple compacts in a long session
    // but prevents rapid-fire triggers
    return;
  }

  const detection = detectPhaseFromTerminal();

  if (detection.detected) {
    const { phase, nextPhase } = detection;

    // Check if this is a new phase transition (not duplicate)
    if (phaseState.lastPhase !== phase) {
      // Generate project ID if this is brainstorming completion
      if (phase === 'brainstorming') {
        const designFile = extractDesignFileFromTerminal();
        if (designFile) {
          const projectId = generateProjectId(designFile);
          const projectData = getProjectId();
          projectData.currentProject = projectId;
          saveProjectId(projectData);
        }
      }

      // Trigger the pre-compact flow
      triggerPreCompactFlow(phase, nextPhase);
    }
  }
}

main();
