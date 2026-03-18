#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime, timezone

WORKSPACE = os.environ.get('OPENCLAW_WORKSPACE', os.getcwd())
LEDGER = os.path.join(WORKSPACE, '.supervision', 'pending-jobs.json')


def now():
    return datetime.now(timezone.utc).isoformat()


def load():
    if not os.path.exists(LEDGER):
        return {'version': 1, 'jobs': []}
    with open(LEDGER, 'r', encoding='utf-8') as f:
        return json.load(f)


def save(data):
    os.makedirs(os.path.dirname(LEDGER), exist_ok=True)
    with open(LEDGER, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=True, indent=2)
        f.write('\n')


def find_job(data, job_id):
    for job in data.get('jobs', []):
        if job.get('id') == job_id:
            return job
    return None


def cmd_add(args):
    if len(args) < 2:
        raise SystemExit('usage: task_ledger.py add <id> <title>')
    job_id, title = args[0], args[1]
    data = load()
    job = find_job(data, job_id)
    stamp = now()
    if job is None:
        job = {
            'id': job_id,
            'title': title,
            'status': 'running',
            'startedAt': stamp,
            'lastUpdatedAt': stamp,
            'lastAction': 'Task created',
            'nextStep': '',
            'userUpdated': True,
            'chatId': '',
        }
        data['jobs'].append(job)
    else:
        job['title'] = title
        job['lastUpdatedAt'] = stamp
    save(data)


def cmd_update(args):
    if len(args) < 3:
        raise SystemExit('usage: task_ledger.py update <id> <field> <value>')
    job_id, field, value = args[0], args[1], args[2]
    data = load()
    job = find_job(data, job_id)
    if job is None:
        raise SystemExit(f'job not found: {job_id}')
    if value in ('true', 'false'):
        parsed = value == 'true'
    else:
        parsed = value
    job[field] = parsed
    job['lastUpdatedAt'] = now()
    save(data)


def cmd_list(_args):
    print(json.dumps(load(), ensure_ascii=True, indent=2))


def main():
    if len(sys.argv) < 2:
        raise SystemExit('usage: task_ledger.py <add|update|list> ...')
    cmd = sys.argv[1]
    args = sys.argv[2:]
    if cmd == 'add':
        cmd_add(args)
    elif cmd == 'update':
        cmd_update(args)
    elif cmd == 'list':
        cmd_list(args)
    else:
        raise SystemExit(f'unknown command: {cmd}')


if __name__ == '__main__':
    main()
