# Installing Aetheric

Aetheric is three things that share one daemon:

| Product | What it is | Get it |
| --- | --- | --- |
| **aetheric** (daemon + CLI) | One binary: the API server, the agents' runner, and the `aetheric` command | `install.sh` / `install.ps1`, or Homebrew |
| **Aetheric Desktop** | The app, with its own copy of the daemon | AppImage / .deb, .dmg, Windows installer |
| **Aetheric for Android** | The app for your phone; drives a daemon on your computer | APK from the releases page |

Releases live in the public releases repo, named in the install commands below.

## The daemon and CLI

Linux and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/JamesBarnes88/aetheric-releases/main/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/JamesBarnes88/aetheric-releases/main/install.ps1 | iex
```

Homebrew: `brew install <owner>/<tap>/aetheric`, once the tap is published.

The installers check each download against the release's `SHA256SUMS`. Then:

```bash
aetheric doctor --fix                 # checks git, downloads Claude Code, checks your sign-in
aetheric auth login claude            # if doctor says you're not signed in
aetheric service install              # run the daemon with your session (systemd / launchd / logon task)
aetheric status
```

Needs: git. Claude Code is downloaded for you (the exact version Aetheric is built against).
Your Claude sign-in is Claude Code's own, in your home folder; Aetheric never sees the
credentials.

## Your phone

The daemon listens on this machine only until you open it up. Over Tailscale (encrypted, works
away from home):

```bash
aetheric remote enable --tailscale
aetheric pair                          # a one-time code and QR, valid 5 minutes
```

In the Android app, choose **Connect** and scan the QR (or enter the address and the code).
`aetheric devices` lists paired devices; `aetheric devices revoke <name>` cuts one off at once.
Same Wi-Fi without Tailscale: `aetheric remote enable --lan` (the traffic is not encrypted there).

## The desktop app

Install it and open it: it uses the daemon already running for you, or starts its own. To pair a
phone, use **Settings › Devices**. To drive Aetheric on another computer, enter that machine's
address and a code from `aetheric pair` there under **This app connects to**.

## Updating

- CLI: `aetheric update` (checks the release's checksum, then restarts a running daemon onto it).
- Desktop: updates itself in the background and installs on quit.
- Android: the app offers new builds published to your daemon.

## Where things live

| | Linux | macOS | Windows |
| --- | --- | --- | --- |
| Data (database, config, logs, backups) | `~/.local/share/aetheric` | `~/Library/Application Support/Aetheric` | `%APPDATA%\Aetheric` |
| CLI binary | `~/.local/bin/aetheric` | `~/.local/bin/aetheric` | `%LOCALAPPDATA%\Programs\Aetheric` |

`aetheric backup create` archives your data; `aetheric migrate export` / `import --remap old=new`
move it to another machine. `aetheric help` lists everything.
