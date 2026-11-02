"""Original, deterministic synthesized ambient loops; no third-party recordings."""
import math
import random
import struct
import wave
from pathlib import Path

rate = 22050
seconds = 20
out = Path(__file__).resolve().parents[1] / 'Malrang/Resources'
for index, sound in enumerate(('rain', 'fire', 'wave', 'forest', 'cafe', 'noise')):
    rng = random.Random(1024 + index)
    samples = []
    low = 0.0
    for i in range(rate * seconds):
        t = i / rate
        noise = rng.uniform(-1, 1)
        low = low * .97 + noise * .03
        if sound == 'rain': value = noise * .16 + low * .9 + math.sin(t * 2933) * max(0, math.sin(t * 11.7)) ** 90 * .08
        elif sound == 'fire': value = low * 1.9 + noise * .07 + noise * max(0, math.sin(t * 31.1) * math.sin(t * 13.3)) ** 24 * .5
        elif sound == 'wave': value = (low * 2 + noise * .08) * (.45 + .55 * math.sin(math.pi * t / 5) ** 2)
        elif sound == 'forest':
            chirp = max(0, math.sin(t * 1.4)) ** 28
            value = low * .8 + .12 * chirp * math.sin(2 * math.pi * (2200 * t + 90 * math.sin(t * 23)))
        elif sound == 'cafe': value = low * 1.5 + .04 * math.sin(t * 710) * math.sin(t * 17) + .035 * math.sin(t * 901) * max(0, math.sin(t * 2.8)) ** 20
        else: value = noise * .22
        samples.append(value)
    # Wrap the last half-second into the beginning to remove the loop boundary click.
    cross = rate // 2
    for i in range(cross):
        mix = i / cross
        samples[i] = samples[-cross + i] * (1-mix) + samples[i] * mix
    with wave.open(str(out / f'ambient_{sound}.wav'), 'wb') as f:
        f.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
        f.writeframes(b''.join(struct.pack('<h', int(max(-.95, min(.95, n)) * 32767)) for n in samples[:-cross]))
print('Wrote six original ambient loops.')
