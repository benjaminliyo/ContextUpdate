/**
 * Context Update plugin for OpenCode.ai
 *
 * Registers the context-update skill so OpenCode discovers it, and injects
 * a short session-start nudge into the first user message of each session
 * so the agent remembers to run a drift check before declaring the session
 * done.
 *
 * Unlike a bootstrap-style plugin, this does NOT inline SKILL.md — the
 * skill body is invoke-on-demand (matched via the frontmatter description
 * or by `/context-update`). The injected nudge is the same ~80-word block
 * that Claude Code, Cursor, and Codex receive via their SessionStart hooks.
 *
 * The nudge text itself is loaded from hooks/nudge.txt — single source of
 * truth shared with the bash hook script, the Pi extension, and the Kimi
 * nudge skill.
 */

import path from 'path';
import fs from 'fs';
import os from 'os';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const NUDGE_MARKER = 'CONTEXT-UPDATE-REMINDER';
const NUDGE_PATH = path.resolve(__dirname, '../../hooks/nudge.txt');

// Cache the nudge text once per process — the file does not change during a
// session and the hook fires on every agent step.
let _nudgeCache; // undefined = not loaded, null = file missing
const getNudge = () => {
  if (_nudgeCache !== undefined) return _nudgeCache;
  try {
    _nudgeCache = fs.readFileSync(NUDGE_PATH, 'utf8').trim();
  } catch {
    _nudgeCache = null;
  }
  return _nudgeCache;
};

const normalizePath = (p, homeDir) => {
  if (!p || typeof p !== 'string') return null;
  let normalized = p.trim();
  if (!normalized) return null;
  if (normalized.startsWith('~/')) {
    normalized = path.join(homeDir, normalized.slice(2));
  } else if (normalized === '~') {
    normalized = homeDir;
  }
  return path.resolve(normalized);
};

export const ContextUpdatePlugin = async ({ client, directory }) => {
  const homeDir = os.homedir();
  const skillsDir = path.resolve(__dirname, '../../skills');
  const envConfigDir = normalizePath(process.env.OPENCODE_CONFIG_DIR, homeDir);
  // configDir computed for parity with the superpowers plugin pattern;
  // not used directly here but available for future config-aware features.
  const _configDir = envConfigDir || path.join(homeDir, '.config/opencode');

  return {
    // Register the skills directory so OpenCode's lazy skill discovery
    // finds context-update without symlinks or manual config edits.
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) {
        config.skills.paths.push(skillsDir);
      }
    },

    // Inject the session-start nudge into the first user message.
    // Same pattern as superpowers, but the payload is the short reminder
    // block rather than the full SKILL.md body — context-update is
    // invoke-on-demand, not always-loaded.
    'experimental.chat.messages.transform': async (_input, output) => {
      const nudge = getNudge();
      if (!nudge || !output.messages.length) return;
      const firstUser = output.messages.find(m => m.info.role === 'user');
      if (!firstUser || !firstUser.parts.length) return;

      if (firstUser.parts.some(p => p.type === 'text' && p.text.includes(NUDGE_MARKER))) return;

      const ref = firstUser.parts[0];
      firstUser.parts.unshift({ ...ref, type: 'text', text: nudge });
    }
  };
};
