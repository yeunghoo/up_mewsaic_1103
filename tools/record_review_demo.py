"""Record an explicitly identified simulator demonstration using normal UI actions."""
import argparse
import os
from pathlib import Path
import signal
import subprocess
import time

p = argparse.ArgumentParser()
p.add_argument('--device', required=True)
p.add_argument('--xctestrun', required=True)
p.add_argument('--output', required=True)
args = p.parse_args()
out = Path(args.output).resolve()
out.mkdir(parents=True, exist_ok=True)
log = out / 'walkthrough.log'
record_log = out / 'recording.log'
video = out / 'Mewsaic-Nook-1.0.0-Simulator-Demo-raw.mov'
if video.exists():
    raise SystemExit('Use a fresh output directory; recording already exists.')
env = dict(os.environ, TEST_RUNNER_MC_RECORD_DEMO='1')
command = ['xcodebuild', 'test-without-building', '-xctestrun', args.xctestrun,
           '-destination', 'platform=iOS Simulator,id=' + args.device,
           '-parallel-testing-enabled', 'NO',
           '-only-testing:loop_miaoUITests/MCReviewWalkthrough/testRecordVersion100']
record = None
complete = False
try:
    with log.open('w') as stream, record_log.open('w') as record_stream:
        run = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT, env=env)
        deadline = time.monotonic() + 480
        while run.poll() is None and time.monotonic() < deadline:
            content = log.read_text(errors='replace')
            if record is None and 'REVIEW_RECORD_READY' in content:
                record = subprocess.Popen(['xcrun', 'simctl', 'io', args.device,
                    'recordVideo', '--codec=h264', str(video)],
                    stdout=record_stream, stderr=subprocess.STDOUT)
                print('Recording normal gameplay on simulator.', flush=True)
            if 'REVIEW_RECORD_DONE' in content:
                complete = True
                break
            time.sleep(.25)
        if record is not None and record.poll() is None:
            record.send_signal(signal.SIGINT)
            record.wait(timeout=45)
        if not complete and run.poll() is None:
            run.terminate()
        code = run.wait(timeout=45)
        print('Walkthrough exit:', code, 'Complete:', complete, flush=True)
        if code or not complete:
            raise SystemExit('Incomplete demonstration; inspect walkthrough.log before using video.')
finally:
    if record is not None and record.poll() is None:
        record.send_signal(signal.SIGINT)
        record.wait(timeout=45)
print(video, flush=True)
