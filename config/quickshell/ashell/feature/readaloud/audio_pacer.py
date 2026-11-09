#!/usr/bin/env python3
"""
feature/readaloud/audio_pacer.py
Reads raw 16-bit PCM from stdin, calculates RMS audio levels,
paces playback, writes PCM to pw-play, and outputs LEVEL:<norm> to stdout.
"""
import sys
import os
import signal
import subprocess
import struct
import math
import time
import atexit

pw_proc = None

def cleanup(sig=None, frame=None):
    global pw_proc
    try:
        if pw_proc and pw_proc.poll() is None:
            pw_proc.terminate()
            try:
                pw_proc.wait(timeout=0.1)
            except subprocess.TimeoutExpired:
                pw_proc.kill()
    except Exception:
        pass
    if sig is not None:
        sys.exit(0)

atexit.register(cleanup)
signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGHUP, cleanup)

def main():
    global pw_proc
    rate = int(sys.argv[1]) if len(sys.argv) > 1 else 22050
    chunk_duration = 0.04  # 40ms = 25 level updates per second
    chunk_samples = int(rate * chunk_duration)
    chunk_bytes = chunk_samples * 2  # 16-bit mono = 2 bytes per sample

    pw_cmd = ["pw-play", "--raw", "--rate", str(rate), "--channels", "1", "--format", "s16", "-"]
    try:
        pw_proc = subprocess.Popen(pw_cmd, stdin=subprocess.PIPE)
    except Exception as e:
        sys.stdout.write(f"ERROR:pw_play_failed:{e}\n")
        sys.stdout.flush()
        sys.exit(1)

    start_time = time.monotonic()
    frames_sent = 0

    try:
        while True:
            chunk = sys.stdin.buffer.read(chunk_bytes)
            if not chunk:
                break

            try:
                pw_proc.stdin.write(chunk)
                pw_proc.stdin.flush()
            except (BrokenPipeError, OSError):
                break

            frames_sent += 1

            num_samples = len(chunk) // 2
            if num_samples > 0:
                samples = struct.unpack(f"<{num_samples}h", chunk[:num_samples * 2])
                sq_sum = sum(s * s for s in samples)
                rms = math.sqrt(sq_sum / num_samples)
                # RMS amplitude with perceptual dynamic range curve
                norm = min(1.0, max(0.0, (rms / 13500.0) ** 0.85)) if rms > 50 else 0.0
                sys.stdout.write(f"LEVEL:{norm:.3f}\n")
                sys.stdout.flush()

            # Real-time pacing to synchronize audio with waveform
            target_time = start_time + (frames_sent * chunk_duration)
            now = time.monotonic()
            sleep_dur = target_time - now
            if sleep_dur > 0:
                time.sleep(sleep_dur)

        # Input stream finished; allow PipeWire buffer to drain
        if pw_proc and pw_proc.stdin:
            pw_proc.stdin.close()
        if pw_proc:
            pw_proc.wait()

        sys.stdout.write("LEVEL:0.000\nSTATUS:finished\n")
        sys.stdout.flush()
    except (BrokenPipeError, KeyboardInterrupt):
        pass
    finally:
        cleanup()

if __name__ == "__main__":
    main()
