"""Gymco's celebration sounds, synthesised so there is nothing to license.

    python3 tool/make_sounds.py

award.wav: a rising four-note bell arpeggio with a soft shimmer, for an
award unlocked. day.wav: two quick bright notes, for a day kept.
Mono, 44.1 kHz, 16-bit, gentle fades so nothing clicks.
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets/sounds"


def bell(freq: float, t: float, decay: float) -> float:
    # A bell: the fundamental plus inharmonic partials that die away faster.
    env = math.exp(-t / decay)
    s = math.sin(2 * math.pi * freq * t)
    s += 0.45 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-t / (decay * 0.45))
    s += 0.25 * math.sin(2 * math.pi * freq * 5.40 * t) * math.exp(-t / (decay * 0.25))
    s += 0.18 * math.sin(2 * math.pi * freq * 2.0 * t)
    attack = min(1.0, t / 0.004)
    return s * env * attack


def render(notes, length, shimmer=0.0, gain=0.32):
    n = int(RATE * length)
    buf = [0.0] * n
    for start, freq, decay, amp in notes:
        s0 = int(start * RATE)
        for i in range(s0, n):
            buf[i] += amp * bell(freq, (i - s0) / RATE, decay)
    if shimmer:
        rnd = random.Random(7)
        # Sparkles: short high pings scattered over the tail.
        for _ in range(26):
            st = rnd.uniform(0.25, length - 0.35)
            f = rnd.uniform(2600, 4200)
            s0 = int(st * RATE)
            for i in range(s0, min(n, s0 + int(0.25 * RATE))):
                buf[i] += shimmer * bell(f, (i - s0) / RATE, 0.05)
    peak = max(abs(x) for x in buf) or 1
    fade = int(0.08 * RATE)
    frames = bytearray()
    for i, x in enumerate(buf):
        v = x / peak * gain * 1.9
        if i > n - fade:
            v *= (n - i) / fade
        frames += struct.pack("<h", int(max(-1, min(1, v)) * 32767))
    return bytes(frames)


def save(name, data):
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    print("wrote", name, len(data) // 2 / RATE, "s")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    c5, e5, g5, c6, e6 = 523.25, 659.25, 783.99, 1046.5, 1318.5
    save("award.wav", render([(0.00, c5, 0.9, 0.9), (0.11, e5, 0.9, 0.85), (0.22, g5, 1.0, 0.85), (0.36, c6, 1.4, 1.0), (0.36, e6, 1.2, 0.35)], 1.9, shimmer=0.12))
    save("day.wav", render([(0.00, g5, 0.45, 0.9), (0.09, c6, 0.7, 1.0)], 0.9, gain=0.26))


if __name__ == "__main__":
    main()
