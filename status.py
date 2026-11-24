#!/usr/bin/env python3
"""Read only Yogurt session metadata. Never read audio, transcripts or notes."""
import argparse
import json
import os
from pathlib import Path
import sqlite3
import time
from urllib.parse import quote


def snapshot(profile=None):
    directory = Path(profile).expanduser() if profile else Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'Yogurt'
    database = directory / 'yogurt.db'
    if not database.is_file():
        return {'available': False, 'recording': None, 'recent': [], 'message': 'no-library'}
    try:
        # mode=ro must not be replaced by immutable=1: an active WAL holds live state.
        with sqlite3.connect('file:' + quote(str(database), safe='/') + '?mode=ro', uri=True, timeout=0.2) as connection:
            connection.execute('PRAGMA query_only=ON')
            connection.row_factory = sqlite3.Row
            columns = {row[1] for row in connection.execute('PRAGMA table_info(meetings)')}
            required = {'id', 'title', 'state', 'started_at', 'ended_at'}
            if not required <= columns:
                return {'available': False, 'recording': None, 'recent': [], 'message': 'unsupported-library'}
            optional = [column for column in ('duration_ms', 'transcription_state', 'transcription_pending', 'trashed_at') if column in columns]
            selected = ','.join(['id', 'title', 'state', 'started_at', 'ended_at'] + optional)
            where = 'WHERE trashed_at IS NULL' if 'trashed_at' in columns else ''
            rows = connection.execute(f'SELECT {selected} FROM meetings {where} ORDER BY started_at DESC LIMIT 12').fetchall()
            sessions = []
            for row in rows:
                value = dict(row)
                started = value.get('started_at')
                ended = value.get('ended_at')
                if not isinstance(started, (float, int)) or started < 0:
                    continue
                duration = value.get('duration_ms')
                if duration is None and isinstance(ended, (int, float)):
                    duration = max(0, ended - started)
                sessions.append({
                    'id': str(value['id'])[:128], 'title': str(value.get('title') or '')[:160],
                    'state': str(value['state'])[:32], 'startedAt': started,
                    'durationMs': max(0, duration or 0),
                    'transcriptionState': str(value.get('transcription_state') or '')[:32],
                    'pending': bool(value.get('transcription_pending', False)),
                })
            return {'available': True, 'recording': next((row for row in sessions if row['state'] == 'recording'), None),
                    'recent': [row for row in sessions if row['state'] not in ('recording', 'prepared')][:3],
                    'updatedAt': int(time.time() * 1000), 'message': ''}
    except (sqlite3.Error, OSError, ValueError, TypeError):
        return {'available': False, 'recording': None, 'recent': [], 'message': 'library-unavailable'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', help='Directory containing Yogurt\'s yogurt.db')
    args = parser.parse_args()
    print(json.dumps(snapshot(args.profile), ensure_ascii=True))


if __name__ == '__main__':
    main()
