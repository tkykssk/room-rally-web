"""Synthesise the game's sound effects and BGM loop (no external samples).

Usage: python3 tools/gen_audio.py   (needs numpy and ffmpeg with libvorbis)
Writes .ogg files into ../audio/.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = np.random.default_rng(7)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack=0.005, release=None, curve=4.0):
    """Fast attack, exponential-ish decay over n samples."""
    t = np.linspace(0.0, 1.0, n)
    a = np.clip(np.arange(n) / max(1, int(SR * attack)), 0, 1)
    d = (1.0 - t) ** curve if release is None else np.exp(-np.arange(n) / (SR * release))
    return a * d


def sweep(f0, f1, dur, wave_fn=np.sin):
    t = t_axis(dur)
    f = np.geomspace(f0, f1, len(t))
    phase = 2 * np.pi * np.cumsum(f) / SR
    return wave_fn(phase)


def square(phase, duty=0.5):
    return np.where((phase / (2 * np.pi)) % 1.0 < duty, 1.0, -1.0)


def tri(phase):
    return 2.0 / np.pi * np.arcsin(np.sin(phase))


def tone(freq, dur, kind="sine", duty=0.5, vib=0.0):
    t = t_axis(dur)
    f = freq * (1.0 + vib * np.sin(2 * np.pi * 5.5 * t))
    phase = 2 * np.pi * np.cumsum(f) / SR
    if kind == "square":
        return square(phase, duty)
    if kind == "tri":
        return tri(phase)
    return np.sin(phase)


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def note(name):
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    semis = names[name[0]] + (1 if "#" in name else 0)
    octave = int(name[-1])
    return 440.0 * 2 ** ((semis + 12 * (octave - 4) - 9) / 12)


def write(name, x, peak=0.89):
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    pcm = (x * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tmp = f.name
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    dst = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4", dst], check=True)
    os.remove(tmp)
    print("wrote", dst)


def mix_at(buf, x, start):
    end = min(len(buf), start + len(x))
    buf[start:end] += x[: end - start]


def sfx():
    # Pickup: bright rising "bloop".
    x = sweep(520, 1250, 0.09) + 0.3 * sweep(1040, 2500, 0.09)
    write("pickup", x * env(len(x), curve=2.5))
    # Bigger pickup: two-step chunky pop with a soft thump.
    a = sweep(260, 520, 0.08, lambda p: tri(p)) * env(int(SR * 0.08), curve=1.5)
    b = sweep(520, 900, 0.12, lambda p: tri(p)) * env(int(SR * 0.12), curve=2.5)
    thump = sweep(140, 60, 0.12) * env(int(SR * 0.12), curve=3)
    x = np.zeros(int(SR * 0.22))
    mix_at(x, a, 0)
    mix_at(x, b, int(SR * 0.07))
    mix_at(x, 0.8 * thump, 0)
    write("pickup_big", x)
    # Size milestone: sparkling arpeggio.
    x = np.zeros(int(SR * 0.9))
    for i, n in enumerate(["C5", "E5", "G5", "C6", "E6"]):
        s = tone(note(n), 0.5, "tri") + 0.4 * tone(note(n) * 2, 0.5)
        mix_at(x, s * env(len(s), release=0.18), int(SR * 0.07 * i))
    write("milestone", x)
    # Bump: low thud.
    s = sweep(150, 55, 0.18) * env(int(SR * 0.18), curve=2.5)
    n = lowpass(noise(0.18), 900) * env(int(SR * 0.18), curve=6)
    write("bump", s + 0.8 * n)
    # Knock-off: descending whoop plus clatter.
    x = np.zeros(int(SR * 0.5))
    mix_at(x, 0.7 * sweep(900, 220, 0.4, lambda p: square(p, 0.3)) * env(int(SR * 0.4), curve=1.5), 0)
    for i in range(5):
        c = lowpass(noise(0.04), 4000) * env(int(SR * 0.04), curve=3)
        mix_at(x, c, int(SR * (0.03 + 0.07 * i + rng.uniform(0, 0.02))))
    write("knock", lowpass(x, 6000))
    # Countdown tick: woodblock.
    s = tone(1300, 0.06) * env(int(SR * 0.06), curve=6) + 0.5 * tone(2600, 0.06) * env(int(SR * 0.06), curve=10)
    write("tick", s)
    # UI click.
    s = tone(900, 0.04, "tri") * env(int(SR * 0.04), curve=4)
    write("click", s, peak=0.6)
    # Start jingle: "pi-po-pa!"
    x = np.zeros(int(SR * 0.6))
    for i, n in enumerate(["G5", "C6", "E6"]):
        d = 0.12 if i < 2 else 0.35
        s = tone(note(n), d, "square", duty=0.25) * env(int(SR * d), curve=1.2)
        mix_at(x, 0.6 * s, int(SR * 0.12 * i))
    write("start", lowpass(x, 5000))
    # Result fanfare.
    x = np.zeros(int(SR * 1.8))
    seq = [("G4", 0.0, 0.15), ("C5", 0.15, 0.15), ("E5", 0.3, 0.15), ("G5", 0.45, 1.2)]
    for n, st, d in seq:
        s = tone(note(n), d, "square", duty=0.3, vib=0.004 if d > 1 else 0) * env(int(SR * d), curve=1.0)
        mix_at(x, 0.5 * s, int(SR * st))
    for n in ["C4", "E4", "G4", "C5"]:
        s = tone(note(n), 1.25, "tri") * env(int(SR * 1.25), curve=1.2)
        mix_at(x, 0.35 * s, int(SR * 0.45))
    write("result", lowpass(x, 5000))


MELODY = [
    "E5 . G5 . A5 G5 E5 .", "C5 . E5 . D5 C5 A4 .", "A4 . C5 . F5 E5 C5 .", "D5 - - . G4 . B4 D5",
    "E5 . G5 . C6 B5 G5 .", "A5 . G5 . E5 . C5 .", "D5 F5 A5 F5 E5 D5 C5 D5", "G5 - - - . . . .",
    "G5 E5 . C5 E5 G5 . C6", "B5 A5 . E5 . C5 E5 .", "F5 . A5 . C6 . A5 F5", "G5 . D5 . B4 . D5 .",
    "E5 G5 C6 G5 E5 G5 C6 E6", "D6 C6 A5 E5 C5 E5 A5 .", "F5 . E5 . D5 . F5 .", "G5 - - - B5 - D6 -",
]
CHORDS = ["C", "Am", "F", "G", "C", "Am", "Dm", "G"] * 2
TRIADS = {"C": ["C4", "E4", "G4"], "Am": ["A3", "C4", "E4"], "F": ["F3", "A3", "C4"],
          "G": ["G3", "B3", "D4"], "Dm": ["D4", "F4", "A4"]}
ROOTS = {"C": ("C2", "G2"), "Am": ("A1", "E2"), "F": ("F1", "C2"), "G": ("G1", "D2"), "Dm": ("D2", "A2")}


def bgm():
    bpm = 124
    eighth = 60.0 / bpm / 2
    bar = eighth * 8
    total = int(SR * bar * len(MELODY))
    out = np.zeros(total)
    for b, (mel, ch) in enumerate(zip(MELODY, CHORDS)):
        t0 = b * bar
        # Melody: soft pulse lead, '-' extends the previous note.
        steps = mel.split()
        i = 0
        while i < 8:
            if steps[i] in (".", "-"):
                i += 1
                continue
            length = 1
            while i + length < 8 and steps[i + length] == "-":
                length += 1
            d = eighth * length * 0.95
            s = tone(note(steps[i]), d, "square", duty=0.25, vib=0.003) * env(int(SR * d), curve=0.8)
            s += 0.5 * tone(note(steps[i]), d, "tri") * env(int(SR * d), curve=0.8)
            mix_at(out, 0.16 * s, int(SR * (t0 + i * eighth)))
            i += length
        # Chord stabs on the off-beats.
        for k in (1, 3, 5, 7):
            for n in TRIADS[ch]:
                s = tone(note(n), eighth * 0.6, "square", duty=0.5) * env(int(SR * eighth * 0.6), curve=2)
                mix_at(out, 0.035 * s, int(SR * (t0 + k * eighth)))
        # Bass: root / fifth bounce.
        root, fifth = ROOTS[ch]
        for k, n in enumerate([root, root, fifth, root]):
            d = eighth * 1.6
            s = tone(note(n) * 2, d, "tri") * env(int(SR * d), curve=1.5)
            mix_at(out, 0.3 * s, int(SR * (t0 + k * 2 * eighth)))
        # Drums.
        for k in range(8):
            st = int(SR * (t0 + k * eighth))
            hat = lowpass(noise(0.03), 9000) - lowpass(noise(0.03), 3000)
            mix_at(out, 0.05 * hat * env(len(hat), curve=6), st)
            if k in (0, 4):
                kick = sweep(110, 45, 0.16) * env(int(SR * 0.16), curve=2.5)
                mix_at(out, 0.45 * kick, st)
            if k in (2, 6):
                sn = lowpass(noise(0.12), 5000) * env(int(SR * 0.12), curve=4)
                mix_at(out, 0.16 * sn, st)
    write("bgm", lowpass(out, 7000), peak=0.7)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    sfx()
    bgm()
