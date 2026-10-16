#!/usr/bin/env python3
"""Generate reports from diagnostic JSONL or normalized BigQuery rows."""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import statistics


def analyze(rows):
    seen, events = set(), []
    for row in rows:
        event_id = row.get('parameters', {}).get('event_id')
        if not event_id or event_id in seen:
            continue
        seen.add(event_id)
        events.append(row)
    events.sort(key=lambda e: (e['at'], e['parameters'].get('event_index') or 0))
    runs, sessions = defaultdict(list), defaultdict(list)
    dwell, exits, deaths, taps, friction, choices = (Counter() for _ in range(6))
    for event in events:
        p, name = event['parameters'], event['name']
        if p.get('run_id'):
            runs[(event.get('player_id'), p['run_id'])].append(event)
        if p.get('session_id'):
            sessions[(event.get('player_id'), p['session_id'])].append(event)
        if name == 'lc_screen_time':
            dwell[p.get('screen', 'unknown')] += max(0, p.get('duration_ms') or 0) / 1000
        if name == 'lc_app_background':
            exits[p.get('screen', 'unknown')] += 1
        if name == 'lc_run_ended' and p.get('outcome') == 'lost':
            deaths[p.get('fatal_location') or p.get('location', 'unknown')] += 1
        if name == 'lc_interaction':
            taps[p.get('target', 'surface')] += 1
        if name == 'lc_heartbeat' and (p.get('idle_seconds') or 0) >= 90:
            friction[f"idle:{p.get('screen', 'unknown')}"] += 1
        if name == 'lc_choice_confirmed':
            choices[f"{p.get('event')} / {p.get('choice')}"] += 1
    outcomes, days, unfinished = Counter(), [], 0
    for run in runs.values():
        ended = [e for e in run if e['name'] == 'lc_run_ended']
        if ended:
            p = ended[-1]['parameters']
            outcomes[p.get('outcome', 'unknown')] += 1
            days.append(p.get('day') or 0)
        else:
            unfinished += 1
    for session in sessions.values():
        streak, last = 0, None
        for event in session:
            if event['name'] == 'lc_interaction':
                target = event['parameters'].get('target')
                streak = streak + 1 if target == last else 1
                last = target
                if streak == 8:
                    friction[f'repeated_input:{target}'] += 1
            elif event['name'] in {'lc_action_result', 'lc_choice_confirmed'}:
                streak = 0
    return dict(events=len(events),
        players=len({e['player_id'] for e in events if e.get('player_id')}),
        sessions=len(sessions), runs=len(runs), outcomes=dict(outcomes),
        unfinished_runs=unfinished, median_end_day=statistics.median(days) if days else None,
        screen_seconds=dict(dwell.most_common()), background_screens=dict(exits.most_common()),
        deaths_by_location=dict(deaths), interactions=dict(taps.most_common(40)),
        choices=dict(choices), friction_candidates=dict(friction),
        event_counts=dict(Counter(e['name'] for e in events)))


def markdown(report):
    lines = ['# Lost Canopy gameplay report', '',
        f"Events: {report['events']} · Players: {report['players']} · Sessions: {report['sessions']} · Runs: {report['runs']}",
        f"Unfinished observed runs: {report['unfinished_runs']} · Median ended day: {report['median_end_day']}", '',
        'Unfinished does not mean abandoned. Backgrounding is not a confirmed quit. Friction candidates do not prove boredom.', '']
    for key in ['outcomes', 'screen_seconds', 'background_screens', 'deaths_by_location', 'choices', 'friction_candidates']:
        lines += [f'## {key.replace("_", " ").title()}', '', '| Item | Value |', '|---|---:|']
        for name, value in report[key].items():
            lines.append(f'| {str(name).replace("|", "/")} | {round(value, 2) if isinstance(value, float) else value} |')
        lines.append('')
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('--out', type=Path, default=Path('analytics-report'))
    args = parser.parse_args()
    report = analyze([json.loads(line) for line in args.input.read_text().splitlines() if line.strip()])
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    (args.out / 'report.md').write_text(markdown(report))
    print(args.out / 'report.md')


if __name__ == '__main__':
    main()
