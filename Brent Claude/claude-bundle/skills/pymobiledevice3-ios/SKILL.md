---
name: pymobiledevice3-ios
description: Use pymobiledevice3 for headless physical iPhone/iPad testing — scoped os.Logger streaming (no sudo, no Console.app), DVT screenshots (iOS 17+), app-scoped log capture to disk. Use whenever you need to read logs written via `os.Logger`/`Logger` from an installed app, grab a screenshot from a real device, or iterate on-device without touching the UI. Pairs with xcodebuild/devicectl — those handle build/install/launch, this handles capture. Also use whenever `os.Logger` / `Logger` output is missing from `devicectl --console` (which only captures stdout/stderr / NSLog), or you're tempted to add NSLog just to see log lines — reach for `pymobiledevice3 syslog live -pn <ProcessName>` instead.
---

# pymobiledevice3 on-device workflow

**Scope.** XcodeBuildMCP (the `xcodebuildmcp` skill) covers build, install, launch, stop, and bundle-id discovery on physical devices when its `device` workflow is enabled — prefer it for those steps. pymobiledevice3 fills the two gaps MCP and Apple's own `devicectl` don't handle on a real device:

1. **`os.Logger` / `Logger` unified-log streaming** scoped to one process, without sudo.
2. **Screenshots** (DVT channel — `devicectl` has no screenshot verb and `idevicescreenshot` is broken on iOS 17+).

`devicectl --console` only captures stdout/stderr (NSLog/print). Structured `Logger` output goes to the unified log, which normally requires sudo and unscoped `log stream` firehose. pymobiledevice3 solves that cleanly.

Install (one-time) — use **pipx**. Homebrew's Python is externally-managed (PEP 668) so a plain `pip install --user` errors out, and Xcode's Python 3.9 still isn't an option because iOS 18.2 dropped QUIC and pymobiledevice3's TCP fallback needs 3.13+:

```bash
brew install pipx python@3.14            # if not already installed
pipx install --python python3.14 pymobiledevice3
# → /Users/benbyrnes/.local/bin/pymobiledevice3   (pipx venv at ~/.local/pipx/venvs/pymobiledevice3)
pymobiledevice3 version                   # sanity check
```

Verify the binary is the 3.14 one, not some leftover:

```bash
ls -la "$(command -v pymobiledevice3)"                    # → symlink into ~/.local/pipx/venvs/…
head -1 ~/.local/pipx/venvs/pymobiledevice3/bin/pymobiledevice3   # shebang must be the venv Python, NOT /Applications/Xcode.app/…/Python
```

If you see `/Applications/Xcode.app/Contents/Developer/usr/bin/python3` in the shebang, you're on the broken Python 3.9 install (the one `pip3 install pymobiledevice3` lands in). Delete that copy and reinstall via pipx as above.

Under `sudo`, PATH is reset to `secure_path`, which does NOT include `~/.local/bin`. **Always use the absolute path when running tunneld as root** — otherwise sudo may not find `pymobiledevice3` at all, or worse, find a different one:

```bash
sudo /Users/benbyrnes/.local/bin/pymobiledevice3 remote tunneld 2>&1 | tee /tmp/tunneld.log
```

## Live log streaming (scoped to one app)

```bash
# wired device; filter by process name — only logs from GlutenMeNot.app
python3 -m pymobiledevice3 syslog live -pn GlutenMeNot
```

- Captures `os.Logger` / `Logger` entries (subsystem+category), `NSLog`, `print` — everything the process emits.
- Respects privacy redaction: `<private>` shows up unless every interpolation carries `privacy: .public`.
- **iOS 17+ needs tunneld even over USB.** Apple moved developer services (DVT screenshot, RemoteXPC `syslog live` channel) off the classic usbmux socket onto RemoteXPC-over-USB-CDC-NCM (the `anpi0` USB-ethernet interface). USB no longer bypasses the tunnel. Classic usbmux calls (`usbmux list`, `afc`, `mounter`) still work cable-only; anything under `developer` or `syslog live` does not.
- Start a tunnel first, wired or wireless (use the same 3.13+ interpreter; see Install note above):
  ```bash
  sudo python3.14 -m pymobiledevice3 remote tunneld 2>&1 | tee /tmp/tunneld.log &    # long-running daemon, keep running
  # or one-shot per-command:
  sudo python3.14 -m pymobiledevice3 remote start-tunnel &
  python3.14 -m pymobiledevice3 syslog live --tunnel <UDID> -pn <ProcessName>
  ```
  Grep `/tmp/tunneld.log` for `QuicProtocolNotSupportedError` before trusting it — if you see it, you're on Python 3.9 and no tunnel will come up (wired *or* wireless).

Capture pattern — run in background, grep later:
```bash
python3 -m pymobiledevice3 syslog live -pn GlutenMeNot > /tmp/<app>-live.log 2>&1 &
BG=$!
# ... user reproduces the issue ...
sleep 10
kill $BG; wait 2>/dev/null
grep "<your tag>" /tmp/<app>-live.log
```

## Screenshots (DVT)

`devicectl` has no screenshot verb. `idevicescreenshot` is broken on iOS 17+. `pymobiledevice3` works — but on iOS 17+ DVT always goes through the RemoteXPC tunnel, **including over USB**:

```bash
# iOS 17+ (wired or wireless) — tunneld must be up under Python 3.13+
sudo /Users/benbyrnes/.local/bin/pymobiledevice3 remote tunneld 2>&1 | tee /tmp/tunneld.log
# (in another shell) — --tunnel is required, even with exactly one device paired
pymobiledevice3 developer dvt screenshot /tmp/<app>-shot.png --tunnel <UDID>
# or set once per shell:
export PYMOBILEDEVICE3_TUNNEL=<UDID>
pymobiledevice3 developer dvt screenshot /tmp/<app>-shot.png
```

Discover the UDID tunneld is serving with `curl -s http://127.0.0.1:49151` — it returns JSON like `{"00008112-0015685222DA201E":[{"tunnel-address":"fdeb:…","tunnel-port":62870,"interface":"169.254.181.194"}]}`. That's the ECID-format UDID (pymobiledevice3 + tunneld), not the CoreDevice UUID (`xcrun devicectl`) — don't cross them.

**"Device is not connected" is ambiguous.** Two very different causes produce the same message:
1. No completed tunnel exists (tunneld broken / wrong Python / device not paired). Grep `/tmp/tunneld.log` for `QuicProtocolNotSupportedError` or `Created tunnel`.
2. Tunnel exists but you didn't tell the CLI which one to use — i.e. you forgot `--tunnel <UDID>`. `curl 127.0.0.1:49151` proves a tunnel is there; the fix is the flag, not a tunneld restart.

PNG lands on the Mac filesystem; use with `Read` to view it.

## Iteration loop

Prefer XcodeBuildMCP for the build/install/launch trio; pymobiledevice3 handles capture. Load the `xcodebuildmcp` skill first so you get the canonical tool calls and the `session_show_defaults` convention.

```
edit code
  → MCP: device build-and-run (one call — builds, installs, launches)
     fallback if device workflow isn't enabled in .xcodebuildmcp/config.yaml:
     xcodebuild ... build
     xcrun devicectl device install app --device <DEVICECTL_UUID> "$APP"
     xcrun devicectl device process launch --device <DEVICECTL_UUID> <BUNDLE_ID>
  → python3 -m pymobiledevice3 syslog live -pn <ProcessName> > /tmp/<app>-live.log &
  → wait / let user reproduce
  → grep log, pymobiledevice3 screenshot as needed
  → kill background streamer
  → edit → repeat
```

Only step that requires the human is physically pointing the device at whatever the camera should see.

## Gotchas

- **Python 3.13+ is mandatory for iOS 18.2+ tunnels (wired AND wireless).** iOS 18.2 dropped QUIC; pymobiledevice3's TCP transport requires 3.13+. Symptoms when you're on 3.9: `start-tunnel-task-wifi-… QuicProtocolNotSupportedError: iOS 18.2+ removed QUIC protocol support. Use TCP instead (requires python3.13+)` repeating forever, **and** `handle-new-potential-usb-cdc-ncm-interface-task-…%anpi0 … asyncio.exceptions.TimeoutError` on the USB-CDC-NCM handshake (the `wifi-` prefix is the tunnel-task naming, not the transport — `anpi0` is the USB-ethernet interface, i.e. the cable). Net effect: tunneld is up but no tunnel ever completes, so the iPad looks "invisible" to `developer dvt screenshot` / `syslog live --tunnel` even when plugged in. Fix: reinstall under `python3.14 -m pip install --user pymobiledevice3`, kill the old `sudo … remote tunneld`, and restart with `sudo python3.14 -m pymobiledevice3 remote tunneld`.
- **Two UDIDs.** `xcodebuild` wants the ECID (`xcodebuild -showdestinations`). `devicectl` and `pymobiledevice3` want the CoreDevice UUID (`xcrun devicectl list devices`). Do not cross them.
- **Process name ≠ bundle id.** `-pn GlutenMeNot` (the app name on the home screen / target), not `com.appsonapps.glutenmenot`.
- **Launch before streaming.** `syslog live` starts from now-forward; anything logged before you attach is gone. Launch the app, then start the stream, then reproduce.
- **`--console` still has its place** — it captures stdout/stderr and surfaces crash dyld errors that the unified log doesn't. Use both in parallel when a launch is failing mysteriously.
- **Privacy redaction is real.** If you see `<private>` in the stream, the call site forgot `privacy: .public`. Fix at source; don't try to unredact downstream.
- **Keep it scoped.** Never stream unfiltered syslog — it's gigabytes of system noise. Always pass `-pn` or `--pid`.
