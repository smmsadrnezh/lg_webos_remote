# LG TV Remote Control

`lg` controls an LG webOS TV from the terminal, through a menu or one-line
commands. It is a single Python file that uses only the standard library and
talks to the TV directly. Nothing else needs to be installed.

## Features

- Remote control: use this computer's keyboard to press the TV's remote
  buttons and type into its text fields, and its mouse to move the TV's
  pointer, click and scroll
- Power: turn the TV on (Wake-on-LAN) or off, and turn the screen on or off
- Volume: up, down, set a level, mute and unmute
- Media: play, pause, stop, rewind, fast forward
- Inputs: list them and switch between them (HDMI, etc.)
- Apps: list the installed apps and start one
- Open a URL in the TV's browser (YouTube links open in the YouTube app)
- Show a message on the TV
- Find the TV on the network and pair with it

## Requirements

- Python 3 (part of every Ubuntu install)
- `whiptail` or `dialog` for the menu (`whiptail` is part of every Ubuntu
  install). The one-line commands do not need either.
- The TV and the computer on the same network
- For `lg on`, the TV's *Turn on via Wi-Fi* (or *Mobile TV On*) setting
  must be on

## Installation

```bash
git clone https://github.com/smmsadrnezh/lg_webos_remote.git
install -m 755 lg_webos_remote/lg ~/.local/bin/lg
```

## Setup

Turn the TV on and run:

```bash
lg setup
```

`lg` finds the TV on the network and asks it to pair. Accept the request on
the TV with its remote control. If the TV is not found, give its IP address
(you can find it in the TV's network settings):

```bash
lg setup 192.168.1.50
```

The pairing is kept in `~/.config/lg/config.json`, readable only by you. If
no TV is set up yet, running `lg` offers to do this first.

## Usage

Run `lg` with no arguments to open the menu. Use the arrow keys and Enter to
pick an action, and Esc to go back. What each action did is shown above the
next menu.

Or give a command:

| Command | What it does |
| --- | --- |
| `lg remote` | Control the TV with this keyboard and mouse (see below) |
| `lg on` / `lg off` | Turn the TV on or off |
| `lg screen-on` / `lg screen-off` | Turn the screen on or off; the sound keeps playing |
| `lg volume` | Show the volume |
| `lg volume 15` / `lg volume up` / `lg volume down` | Change the volume |
| `lg mute` / `lg unmute` | Mute or unmute the sound |
| `lg play`, `pause`, `stop`, `rewind`, `forward` | Control what is playing |
| `lg input` | List the inputs |
| `lg input HDMI_2` | Switch to an input |
| `lg app` | List the apps |
| `lg app youtube.leanback.v4` | Start an app |
| `lg open https://example.com` | Open a page in the TV's browser |
| `lg open https://youtu.be/...` | Play a video in the YouTube app |
| `lg notify "Dinner is ready"` | Show a message on the TV |
| `lg button HOME` | Press a remote control button: `HOME`, `BACK`, `UP`, `DOWN`, `LEFT`, `RIGHT`, `ENTER`, `MENU`, `INFO`, `EXIT`, `0` to `9`, ... |
| `lg type "hello"` | Type into the text field selected on the TV |
| `lg help` | List the commands |

To force the menu tool, set `LG_UI=dialog` or `LG_UI=whiptail`.

### Keyboard and mouse

`lg remote` (or *Remote Control* in the menu) turns the terminal window into
a remote control until you press `q`:

| Key | On the TV |
| --- | --- |
| Arrow keys | Move around |
| Enter | OK |
| Backspace or Esc | Back |
| `h` or Home | Home screen |
| `+` and `-` | Volume |
| `m` | Mute |
| `p` / space | Play / pause |
| `0` to `9` | Number keys |
| Tab | Start or stop typing into the TV |
| `q` | Quit (Ctrl+C also quits while typing) |

When a text field on the TV is selected and its on-screen keyboard opens,
`lg` starts typing into it by itself: letters, numbers, symbols and other
scripts such as Persian go straight into the field, Backspace deletes and
Enter submits. Tab or Esc stops typing, so the letter keys work as shortcuts
again.

Moving the mouse over the window moves the TV's pointer: crossing the window
crosses the TV's screen. Click to click, right-click to go back, and use the
wheel to scroll. Terminals that report the mouse in pixels (`lg` asks) give
smoother movement than ones that report it in character cells.

## How it works

The TV accepts commands on a websocket at port 3001, over TLS with a
self-signed certificate, the same API that phone remote apps use.
Before it obeys a client, the TV shows a pairing prompt, and it then gives the
client a key to use from then on. `lg` writes the small websocket client it
needs itself, so it has no dependencies. Remote control buttons and pointer
movements go through a second websocket that the TV opens on request, and
typed text goes to the TV's input method, which also tells `lg` when its
keyboard opens and closes. Turning the TV on is the exception:
the API is not running then, so `lg on` sends a Wake-on-LAN packet to the
TV's hardware address, which is saved when you pair.

When pairing, clients send a manifest listing the permissions they want. Most
open-source clients sign it with an old LG test certificate, and recent LG
firmware rejects that with `403 Pairing rejected: blacklisted certificate
detected`. `lg` sends the manifest unsigned, which the TV accepts.

## Troubleshooting

- **"the TV is off or still starting up"**: in standby the TV still accepts
  connections but hangs up. Turn it on with `lg on` and wait a few seconds.
- **`lg on` does nothing**: turn on *Turn on via Wi-Fi* (or *Mobile TV On*)
  in the TV's settings. If `lg` says the hardware address is unknown, run
  `lg setup` once while the TV is on.
- **"cannot reach the TV"**: check that the TV is on the same network. If its
  IP address changed, run `lg setup` again. Giving the TV a fixed address in
  your router avoids this.
- **No TV found during setup**: the search only reaches TVs that are on.
  Turn the TV on, or run `lg setup IP`.
- **No pairing prompt appears**: the screen must be on. Run `lg setup`
  again while the TV is on.
- **"no text field is selected on the TV"**, or typing does nothing: select
  a text field on the TV first, so that its on-screen keyboard opens. If an
  app draws its own keyboard instead of the TV's, typed text may not reach
  it; use the arrow keys and Enter on that keyboard instead.
- **The mouse does nothing in `lg remote`**: the terminal must report mouse
  events. GNOME Terminal, Ptyxis, Konsole, xterm, kitty and most others do;
  inside tmux, turn on `set -g mouse on`.

## Moving from the `lgtv` version

Earlier versions of this script drove the TV through `lgtv` from
[LGWebOSRemote](https://github.com/klattimer/LGWebOSRemote), and needed
`dialog` and `jq`. None of these are needed any more. Remove `lgtv` with
`pipx uninstall lgtv`, then run `lg setup` once.

## License

This script is provided as-is with no warranty. Feel free to modify and
distribute it according to your needs.
