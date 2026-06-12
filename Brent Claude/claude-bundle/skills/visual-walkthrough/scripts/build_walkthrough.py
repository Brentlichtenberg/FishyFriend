#!/usr/bin/env python3
"""Build a visual HTML walkthrough from a markdown file.

Writes a self-contained HTML file to ~/.diagrams/<slug>.html (configurable).
The HTML loads marked.js and mermaid.js from CDN and renders the markdown
in the browser: any ```mermaid fenced code blocks become real diagrams,
and the H2/H3 heading structure becomes a sticky sidebar TOC with scroll-spy.

Usage:
    build_walkthrough.py <markdown-path>                 # build + open in Mac Safari
    build_walkthrough.py <markdown-path> --no-open       # build only
    build_walkthrough.py <markdown-path> --device BPhone # open on a paired iOS device
    build_walkthrough.py --stop-server                   # stop background LAN server

Opening on a paired iOS device (--device <name>):
    - Starts a local HTTP server serving ~/.diagrams/ on <port> (default 8765),
      binding 0.0.0.0 so the phone can reach it over Wi-Fi.
    - Detects the Mac's LAN IP and builds http://<ip>:<port>/<slug>.html.
    - Launches Safari on the device via `xcrun devicectl` with that URL.
    - The server stays alive across invocations; stop it with --stop-server.
"""

from __future__ import annotations

import argparse
import os
import re
import signal
import subprocess
import sys
import time
from pathlib import Path

DEFAULT_PORT = 8765
SERVER_PID_FILE = ".server.pid"
SERVER_LOG_FILE = ".server.log"
SAFARI_BUNDLE_ID = "com.apple.mobilesafari"


# ---------- markdown → HTML -------------------------------------------------

def slugify(name: str) -> str:
    """Filesystem- and URL-safe version of `name` (lowercase, hyphenated)."""
    name = re.sub(r"[^\w\s-]", "", name).strip().lower()
    name = re.sub(r"[-\s]+", "-", name)
    return name or "walkthrough"


def strip_frontmatter(md: str) -> str:
    """Drop a leading YAML-style `---` front-matter block, if present.

    Front-matter isn't meaningful output — rendering it as a table ruins the
    intro of the walkthrough. Stripping it keeps the first rendered block the
    document's real opening.
    """
    if not md.startswith("---\n"):
        return md
    m = re.search(r"\n---\s*(?:\n|$)", md[4:])
    if not m:
        return md
    return md[4 + m.end():]


def escape_for_script_block(md: str) -> str:
    """Stop a literal </script> in the markdown from terminating the host tag."""
    return md.replace("</script>", "<\\/script>")


def build(md_path: Path, template_path: Path, out_dir: Path) -> Path:
    md = md_path.read_text(encoding="utf-8")
    md = strip_frontmatter(md)
    md = escape_for_script_block(md)

    template = template_path.read_text(encoding="utf-8")
    title = md_path.stem.replace("_", " ").replace("-", " ")

    html = (
        template
        .replace("__TITLE__", title)
        .replace("__MARKDOWN__", md)
    )

    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{slugify(md_path.stem)}.html"
    out_path.write_text(html, encoding="utf-8")
    return out_path


# ---------- Mac Safari ------------------------------------------------------

def open_in_mac_safari(path: Path) -> None:
    try:
        subprocess.run(["open", "-a", "Safari", str(path)], check=True)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"warning: could not open Safari: {e}", file=sys.stderr)


# ---------- LAN server ------------------------------------------------------

def get_lan_ip() -> str | None:
    """Return the IPv4 of the first Wi-Fi / LAN interface we can find."""
    for iface in ("en0", "en1", "en2", "en3"):
        try:
            out = subprocess.check_output(
                ["ipconfig", "getifaddr", iface], text=True
            ).strip()
            if out:
                return out
        except subprocess.CalledProcessError:
            continue
    return None


def _pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except (ProcessLookupError, PermissionError):
        return False
    except OSError:
        return False
    return True


def ensure_server(directory: Path, port: int) -> None:
    """Start `python3 -m http.server` in the background if not already running.

    The PID lives in a file inside `directory` so we can re-use a server across
    invocations. If the PID file references a dead process we overwrite it.
    """
    directory.mkdir(parents=True, exist_ok=True)
    pid_file = directory / SERVER_PID_FILE
    if pid_file.exists():
        try:
            pid = int(pid_file.read_text().strip())
            if _pid_alive(pid):
                return
        except ValueError:
            pass

    log_path = directory / SERVER_LOG_FILE
    log_fh = log_path.open("ab")
    proc = subprocess.Popen(
        [
            sys.executable, "-m", "http.server",
            "--directory", str(directory),
            "--bind", "0.0.0.0",
            str(port),
        ],
        stdout=log_fh,
        stderr=subprocess.STDOUT,
        start_new_session=True,  # detach from our process group
        close_fds=True,
    )
    pid_file.write_text(str(proc.pid))
    # Give http.server a beat to bind before we announce the URL.
    time.sleep(0.4)


def stop_server(directory: Path) -> bool:
    """Terminate a server we previously started. Returns True if one existed."""
    pid_file = directory / SERVER_PID_FILE
    if not pid_file.exists():
        return False
    try:
        pid = int(pid_file.read_text().strip())
        os.kill(pid, signal.SIGTERM)
    except (ValueError, ProcessLookupError):
        pass
    pid_file.unlink(missing_ok=True)
    return True


# ---------- iOS device ------------------------------------------------------

def open_url_on_device(device: str, url: str) -> None:
    """Launch Safari on a paired iOS device with the given URL."""
    subprocess.run(
        [
            "xcrun", "devicectl", "device", "process", "launch",
            "--device", device,
            SAFARI_BUNDLE_ID, url,
        ],
        check=True,
    )


# ---------- main ------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Render a markdown file as a visual HTML walkthrough."
    )
    parser.add_argument(
        "markdown", type=Path, nargs="?",
        help="path to the markdown file (omit when using --stop-server)"
    )
    parser.add_argument(
        "--no-open", action="store_true",
        help="build the HTML but don't open it anywhere"
    )
    parser.add_argument(
        "--out-dir", type=Path, default=Path.home() / ".diagrams",
        help="directory to write the HTML into (default: ~/.diagrams)"
    )
    parser.add_argument(
        "--device", default="mac",
        help=(
            "'mac' (default) opens in Mac Safari. Any other value is treated "
            "as a paired iOS device name/UDID and the URL is opened on that "
            "device via `xcrun devicectl`. Device must be paired in Xcode and "
            "on the same Wi-Fi as this Mac."
        ),
    )
    parser.add_argument(
        "--port", type=int, default=DEFAULT_PORT,
        help=f"port for the LAN server when targeting an iOS device (default: {DEFAULT_PORT})"
    )
    parser.add_argument(
        "--stop-server", action="store_true",
        help="stop the background LAN server and exit"
    )
    args = parser.parse_args()

    out_dir = args.out_dir.expanduser()

    if args.stop_server:
        stopped = stop_server(out_dir)
        print("server stopped" if stopped else "no server was running")
        return 0

    if args.markdown is None:
        parser.error("markdown path is required (unless using --stop-server)")

    md_path = args.markdown.expanduser().resolve()
    if not md_path.is_file():
        print(f"error: not a file: {md_path}", file=sys.stderr)
        return 1

    skill_dir = Path(__file__).resolve().parent.parent
    template_path = skill_dir / "assets" / "template.html"
    if not template_path.is_file():
        print(f"error: template missing at {template_path}", file=sys.stderr)
        return 1

    out_path = build(md_path, template_path, out_dir)
    print(out_path)

    if args.no_open:
        return 0

    if args.device == "mac":
        open_in_mac_safari(out_path)
        return 0

    # iOS device path.
    ip = get_lan_ip()
    if not ip:
        print(
            "error: could not detect a LAN IP (checked en0-en3). "
            "Is Wi-Fi on? You can still serve via the HTTP server and open "
            "the URL manually if you know the Mac's IP.",
            file=sys.stderr,
        )
        return 2

    ensure_server(out_dir, args.port)
    url = f"http://{ip}:{args.port}/{out_path.name}"
    print(f"server: http://{ip}:{args.port}/  (stop with --stop-server)")
    print(f"url:    {url}")

    try:
        open_url_on_device(args.device, url)
    except subprocess.CalledProcessError as e:
        print(
            f"error: devicectl failed (exit {e.returncode}). Is '{args.device}' "
            f"paired and awake? `xcrun devicectl list devices` to check.",
            file=sys.stderr,
        )
        return 3
    except FileNotFoundError:
        print(
            "error: xcrun / devicectl not found. Install Xcode Command Line Tools.",
            file=sys.stderr,
        )
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
