# Persian Incursion Godot Rebuild - Project Checkpoints

## Current Checkpoint

Day 2 in progress - dedicated server executable prototype added.

## Project Location

D:\PersianIncursionGodot\persian-incursion

## Folders Created

- scenes
- scripts
- server

## Files Created

- PROJECT_CHECKPOINTS.md
- server/SERVER_DESIGN.md
- server/game_server.gd
- scripts/server_screen.gd
- scripts/dedicated_server_app.gd
- scripts/app_launcher.gd
- scenes/server_screen.tscn
- scenes/dedicated_server.tscn
- scenes/app_launcher.tscn
- export_presets.cfg
- SERVER_PROTOTYPE_TEST_STEPS.md

## What Works Right Now

- Godot 4.7 stable opens the project.
- The project is clean and separate from last year's Unity project.
- The folder structure is ready for the real server foundation.
- The server design notes are saved.
- The first real server script file exists.
- server/game_server.gd now contains the first real server foundation code.
- GameServer is registered as an autoload singleton in project.godot.
- scenes/server_screen.tscn is set as the main scene.
- The game screen now has Host Game and Join Game flow.
- Join Game opens an IP address popup.
- The game screen shows connection status, local IP, connected players, team buttons, and chat.
- The visible game stats/testing controls were removed from the prototype UI for now.
- A dedicated server window now exists at scenes/dedicated_server.tscn.
- The dedicated server starts automatically, listens on port 9999, shows the IP to share, connected players, and chat/server events.
- The launcher scene decides whether to open the game screen or server screen based on the executable file name.
- If the exported file name contains "server", it opens the dedicated server window.
- If the exported file name does not contain "server", it opens the game Host/Join screen.
- Godot export templates for 4.7 stable were installed on this machine.
- The Windows export presets were added.
- The local builds folder contains:
  - builds/PersianIncursionServer.exe
  - builds/PersianIncursionGame.exe

## Important Note

server/game_server.gd now contains the multiplayer foundation: dedicated server startup, client connection, host-player assignment, player registration, team choice, chat, connect/disconnect messages, action log, and save/load foundations.

## Next Step

Run builds/PersianIncursionServer.exe first, then run builds/PersianIncursionGame.exe. Click Host Game in the game window and confirm the server window shows the host player. Then test a teammate joining from the same Wi-Fi using the IP shown in the server window.
