# Godot projects

| Dir | What |
| --- | --- |
| `room-rally/` | Source of the original Room Rally game, recovered from the shipped `index.pck` (Godot 4.6.3). Scripts were detokenized from `.gdc`, scenes were re-saved as `.tscn`, furniture/food models were re-exported to `.glb`, and the truck/audio/smoke assets come from Kenney's Starter Kit Racing (CC0). |
| `slime-eater/` | Slime Eater: a fork of Room Rally where the player is a slime that eats the room's props. Props are absorbed where they touch the slime, keeping their shape: they sink into the body while a dissolve front eats them away from the contact point, releasing their colours gradually as pigment blobs that slosh inside the body (inertia, buoyancy, membrane collision, viscosity) and diffuse into each other, mixing subtractively (log space) so the body colour changes in real time. Older pigment is slowly digested so recent meals dominate. |

## Building for the web

Both games run on the engine already deployed at the repo root (`index.js` / `index.wasm`, Godot 4.6.3 web, no threads), so only a `.pck` needs exporting — no export templates required:

```sh
cd godot/slime-eater
godot --headless --import
godot --headless --export-pack Web ../../slime/index.pck
```

Then update `"index.pck":<size>` in `fileSizes` in `slime/index.html` (used for the loading bar).

Slime Eater is served at `/slime/`; it loads `../index.wasm` and its own `index.pck`.

Controls: WASD / arrows to move, Space to jump, C to switch camera (touch buttons on mobile).
