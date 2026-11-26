# ASMR recordings

Replaced the synthesized nature loops on 2026-11-26. All five source pages explicitly license their recordings under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

| App sound | Recording / creator | Source |
| --- | --- | --- |
| Rain | Raining In the City Ambience — RyanKingArt | https://freesound.org/people/RyanKingArt/sounds/607228/ |
| Fire | fire_crackling.wav — ceich93 | https://freesound.org/people/ceich93/sounds/263864/ |
| Waves | Calm ocean waves — SamsterBirdies | https://freesound.org/people/SamsterBirdies/sounds/578524/ |
| Forest | Clark's Tower Ambience 1 RX.wav — greysound | https://freesound.org/people/greysound/sounds/547923/ |
| Cafe | 370973__waweee__coffee-shop-ambience_remastered.mp3 — C_Rogers (original recording by waweee) | https://freesound.org/people/C_Rogers/sounds/453074/ |
| White noise | Original independent stereo white noise | Generated in prepare_ambient_recordings.py |

Public HQ previews were downloaded from the CDN URLs embedded in those pages. The app bundles 40-second excerpts (cafe starts at 30 seconds, others at 5 seconds), with a two-second crossfade for continuous looping. White noise is a 30-second original loop. All files are stereo 44.1 kHz/16-bit PCM, DC removed, transient peaks gently compressed, loudness matched with peaks below 0.88. No network is required during playback. Reproduction script: scripts/prepare_ambient_recordings.py.
