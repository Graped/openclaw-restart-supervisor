const fs = require('fs');
const path = require('path');

function resolveWorkspace() {
  return process.env.OPENCLAW_WORKSPACE || process.cwd();
}

function ledgerPath() {
  return path.join(resolveWorkspace(), '.supervision', 'pending-jobs.json');
}

function loadJobs() {
  try {
    const raw = fs.readFileSync(ledgerPath(), 'utf8');
    const data = JSON.parse(raw);
    return Array.isArray(data.jobs) ? data.jobs : [];
  } catch {
    return [];
  }
}

function buildReminder(jobs) {
  const unfinished = jobs.filter((job) =>
    ['running', 'blocked', 'needs_reply'].includes(job.status)
  );

  if (!unfinished.length) {
    return null;
  }

  const lines = unfinished.slice(0, 10).map((job, index) => {
    const nextStep = job.nextStep || 'Decide the next safe action';
    const reply = job.userUpdated ? 'yes' : 'no';
    return `${index + 1}. [${job.status}] ${job.title} | next: ${nextStep} | user updated: ${reply}`;
  });

  return [
    '## Restart Supervision',
    '',
    'Unfinished work was found in `.supervision/pending-jobs.json`.',
    'Before handling new long tasks:',
    '1. Check whether the old task should be resumed, closed, or reported.',
    '2. If the user was not updated, send a short progress note first.',
    '3. Update the ledger after each meaningful step.',
    '',
    'Open items:',
    ...lines,
  ].join('\n');
}

const handler = async (event) => {
  if (!event || event.type !== 'agent' || event.action !== 'bootstrap') {
    return;
  }
  if (!event.context || !Array.isArray(event.context.bootstrapFiles)) {
    return;
  }

  const reminder = buildReminder(loadJobs());
  if (!reminder) {
    return;
  }

  event.context.bootstrapFiles.push({
    path: 'RESTART_SUPERVISION.md',
    content: reminder,
    virtual: true,
  });
};

module.exports = handler;
module.exports.default = handler;
