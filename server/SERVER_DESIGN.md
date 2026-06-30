# Persian Incursion Server Design

## Purpose

This server is the real multiplayer foundation for the Godot remake of Persian Incursion.

It is not a practice server.

The server will eventually control:

- player connections
- lobby state
- team selection
- game state
- turn/day/move state
- Red and Blue points
- political tracks
- save/load
- decks and card river
- action validation
- action log
- rule results

## Main Rule

The server is the truth.

Godot UI should not secretly own important rules. The UI should ask the server to do something. The server checks if it is legal, updates the game state, then tells all clients what changed.

## First Server Checkpoint

The first server version must do only this:

1. Start successfully.
2. Show that it is online.
3. Stop cleanly.
4. Be easy for Godot to connect to later.

This first version is still part of the final project. It will grow one step at a time.
