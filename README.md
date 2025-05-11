# LG TV Remote Control

A bash script that provides a user-friendly terminal interface to control LG WebOS TVs. This script uses dialog boxes to present menus and options, making it easy to control your LG TV from your computer.

## Features

- Power controls (turn TV on/off, screen on/off)
- Volume controls (up, down, set specific level)
- Media controls (play, pause, rewind)
- Input selection (HDMI, etc.)
- Open URLs (including special handling for YouTube)
- Launch apps installed on the TV
- Send notifications to the TV

## Prerequisites

The script requires the following dependencies:

- `lgtv` - A command-line tool for controlling LG WebOS TVs
- `dialog` - A utility for creating TUI dialog boxes
- `jq` - A lightweight and flexible command-line JSON processor

## Installation

1. Clone or download this repository to your local machine.

2. Make the script executable:
   ```bash
   chmod +x lg
   ```

3. Install the required dependencies:

   - Install `lgtv` using pipx:
     ```bash
     pipx install git+https://github.com/klattimer/LGWebOSRemote.git
     ```
     
   - Install `dialog` and `jq` using your package manager:
     ```bash
     # For Debian/Ubuntu
     sudo apt-get install dialog jq
     
     # For Fedora
     sudo dnf install dialog jq
     
     # For Arch Linux
     sudo pacman -S dialog jq
     ```

## Setup

Before using the script, you need to set up the connection to your LG TV:

1. Make sure your TV is turned on and connected to the same network as your computer.

2. Scan for available TVs:
   ```bash
   lgtv scan
   ```

3. Authenticate with your TV (replace `[TV_IP]` with the IP address from the scan):
   ```bash
   lgtv --ssl auth [TV_IP] lgtv
   ```
   This will display a pairing request on your TV. Accept it using your TV remote.

4. Set the default TV:
   ```bash
   lgtv setDefault lgtv
   ```

## Usage

Run the script:
```bash
./lg
```

The script will present a menu with various options:

1. **Power Controls** - Turn the TV on/off or control the screen power
2. **Volume Controls** - Adjust volume or set a specific level
3. **Media Controls** - Play, pause, or rewind media
4. **Set Input** - Select an input source (HDMI, etc.)
5. **Open URL** - Open a URL in the TV's browser (or YouTube app for YouTube URLs)
6. **Start App** - Launch an app installed on the TV
7. **Send Notification** - Display a notification message on the TV

Navigate through the menus using the arrow keys and press Enter to select an option.

## Examples

### Turn the TV On/Off
1. Select "Power Controls" from the main menu
2. Select "TV Power"
3. Choose "Turn TV On" or "Turn TV Off"

### Change Input Source
1. Select "Set Input" from the main menu
2. Choose from the list of available inputs (e.g., "HDMI 1", "HDMI 2")

### Open a YouTube Video
1. Select "Open URL" from the main menu
2. Enter a YouTube URL (e.g., `https://www.youtube.com/watch?v=dQw4w9WgXcQ`)

### Launch an App
1. Select "Start App" from the main menu
2. Choose from the list of installed apps

## Troubleshooting

- **TV Not Found**: Make sure your TV is turned on and connected to the same network as your computer.
- **Authentication Failed**: Try running the auth command again and make sure to accept the pairing request on your TV.
- **Command Failed**: Check the error message displayed in the dialog box. It might indicate a connection issue or an invalid command.
- **JSON Parsing Error**: This usually indicates that the TV is unreachable or the response format has changed.

If you encounter persistent issues, try restarting both your TV and the script.

## License

This script is provided as-is with no warranty. Feel free to modify and distribute it according to your needs.