# Server Prototype Test Steps

## Goal

This prototype uses two app modes:

- `PersianIncursionServer.exe` opens the dedicated server window.
- `PersianIncursionGame.exe` opens the player game window.

Both executables are exported from the same Godot project. The launcher checks the executable file name. If the file name contains `server`, it opens the server window. Otherwise, it opens the game window.

## In Godot Before Exporting

1. Open the project in Godot.
2. Press the play button.
3. The normal game window opens.
4. To test the server scene inside Godot, open `scenes/dedicated_server.tscn` and press **Run Current Scene**.

## Local Same-Computer Test

1. Start the server window first.
2. Start the game window.
3. Type your name.
4. Click **Host Game**.
5. The game connects to `127.0.0.1`, which means the server running on the same computer.
6. The server window should show the host player.
7. Send a chat message from the game window.
8. The chat should appear in both the game window and the server window.

## Teammate Same-Wi-Fi Test

1. The host starts `PersianIncursionServer.exe`.
2. The host reads the IP shown in the server window.
3. The host starts `PersianIncursionGame.exe` and clicks **Host Game**.
4. The teammate starts `PersianIncursionGame.exe`.
5. The teammate clicks **Join Game**.
6. The teammate enters the host IP address.
7. Both players should appear in the connected player list.
8. Chat messages and disconnect messages should appear in the chat box.

## Exporting Executables

1. In Godot, open **Project > Export**.
2. If Godot asks for export templates, install them first.
3. Select **Windows Game** and export it to `builds/PersianIncursionGame.exe`.
4. Select **Windows Server** and export it to `builds/PersianIncursionServer.exe`.
5. Run `PersianIncursionServer.exe` first, then run `PersianIncursionGame.exe`.

## Firewall Note

The first time Windows asks about network access, allow the app on private networks. If this is blocked, teammates on the same Wi-Fi cannot join.
