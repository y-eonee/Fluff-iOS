"""Convert the CC0 recordings listed in AmbientAudioSources.md; never synthesizes nature sounds.
Usage: python3 scripts/prepare_ambient_recordings.py /path/to/downloaded/mp3s
Requires macOS afconvert and numpy. Inputs: rain/fire/wave/forest/cafe.mp3.
"""
import hashlib
import subprocess
import sys
import tempfile
import wave
from pathlib import Path
import numpy as np
source = Path(sys.argv[1])
out = Path(__file__).resolve().parents[1] / 'Malrang/Resources'
rate = 44100
for name in ('rain', 'fire', 'wave', 'forest', 'cafe', 'noise'):
    if name == 'noise':
        samples = np.random.default_rng(20261126).uniform(-1, 1, (rate * 32, 2))
    else:
        with tempfile.TemporaryDirectory() as folder:
            converted = Path(folder) / 'recording.wav'
            subprocess.run(['afconvert', '-f', 'WAVE', '-d', 'LEI16@44100', '-c', '2', str(source / (name + '.mp3')), str(converted)], check=True)
            with wave.open(str(converted)) as audio:
                samples = np.frombuffer(audio.readframes(audio.getnframes()), dtype='<i2').astype(float).reshape(-1, 2) / 32768
        start = rate * (30 if name == 'cafe' else 5)
        samples = samples[start:start + rate * 42]
    samples -= samples.mean(axis=0)
    cross = rate * 2
    fade = np.linspace(0, 1, cross)[:, None]
    seam = samples[-cross:] * (1 - fade) + samples[:cross] * fade
    samples = np.concatenate((samples[cross:-cross], seam))
    # Fireplace transients have a very high crest factor. Gently compress peaks
    # before matching perceived level so its steady crackle is also audible.
    for _ in range(5):
        samples *= 0.11 / np.sqrt(np.mean(samples**2))
        if np.max(np.abs(samples)) <= 0.88:
            break
        samples = 0.55 * np.tanh(samples / 0.55)
    gain = min(0.11 / np.sqrt(np.mean(samples**2)), 0.88 / np.max(np.abs(samples)))
    pcm = np.round(samples * gain * 32767).astype('<i2')
    target = out / ('ambient_' + name + '.wav')
    with wave.open(str(target), 'wb') as audio:
        audio.setnchannels(2); audio.setsampwidth(2); audio.setframerate(rate); audio.writeframes(pcm.tobytes())
    print(name, 'seconds', len(pcm) / rate, 'peak', round(float(np.max(np.abs(pcm))) / 32768, 4), 'sha256', hashlib.sha256(target.read_bytes()).hexdigest())
