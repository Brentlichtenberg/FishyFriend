---
name: visual-walkthrough
description: Render a markdown file as a visual, navigable HTML walkthrough with Mermaid diagrams (flowcharts, sequence diagrams, class diagrams, state diagrams, ER diagrams, mindmaps, timelines, gitGraph), written to ~/.diagrams/<slug>.html and opened in Safari — either on the Mac (default) or on a paired iOS device over Wi-Fi. Use this skill whenever the user says "visualize this doc", "make a walkthrough", "render this as a walkthrough", "show me this plan as diagrams", "turn this into diagrams", "open this in a browser with diagrams", "open this on my phone / iPad", invokes /visual-walkthrough, or passes a .md path and asks to see it visually. Also use proactively when the user has just produced (or is reviewing) a dense architecture / refactor / spec document and says something like "I'm having trouble visualizing this" or "can you show me" — a walkthrough usually serves them better than another wall of prose. Triggers even when the user never says the word "walkthrough"; the signal is "markdown doc + wants to see it visually."
---

# Visual Walkthrough

Render a markdown file as a single-page HTML walkthrough that includes:

- **Mermaid.js diagrams** — any ` ```mermaid ` fenced block becomes a real diagram (flowchart, sequence, class, state, ER, mindmap, timeline, etc.).
- **Sticky sidebar TOC** — built from the markdown's H2/H3 headings, with scroll-spy highlighting the current section.
- **Clean typography** — system font stack, readable line-length, generous spacing, code blocks styled, tables striped.
- **Dark mode** — respects `prefers-color-scheme` automatically; Mermaid theme matches.
- **Zero build step** — loads marked.js and mermaid.js from CDN; runs in any modern browser.

The output is written to `~/.diagrams/<slug>.html` and opened in Safari.

## How to run

The skill ships a Python 3 script (stdlib only) that does the whole job:

```bash
python3 ~/.claude/skills/visual-walkthrough/scripts/build_walkthrough.py <path-to-markdown>
```

Resolve the markdown path to an absolute path before passing it in. The script will:

1. Read the markdown, strip any YAML front-matter.
2. Create `~/.diagrams/` if it doesn't exist.
3. Inject the markdown into the bundled HTML template.
4. Write it to `~/.diagrams/<slug>.html` (slug = filename stem, lowercased, hyphenated).
5. Print the output path and open it in Safari (on the Mac by default).

Flags:

- `--no-open` — build only; don't launch Safari.
- `--out-dir <path>` — write the HTML somewhere other than `~/.diagrams/`.
- `--device <name>` — open on a paired iOS device (see below). `mac` is the default.
- `--port <int>` — port for the LAN server when targeting an iOS device (default `8765`).
- `--stop-server` — stop the background LAN server and exit.

## Opening on an iOS device ("open this on my phone")

When the user asks to see the walkthrough on their phone, iPad, or any iOS device, pass the device name via `--device`. Example for a device named `BPhone`:

```bash
python3 ~/.claude/skills/visual-walkthrough/scripts/build_walkthrough.py \
    /abs/path/doc.md --device BPhone
```

What happens:

1. The HTML is built into `~/.diagrams/<slug>.html` as usual.
2. A background `python3 -m http.server` is started against `~/.diagrams/` on port `8765` (bound to `0.0.0.0` so the phone can reach it over Wi-Fi). The PID lives in `~/.diagrams/.server.pid`; subsequent runs reuse the same server.
3. The Mac's LAN IP is detected via `ipconfig getifaddr en0` (falling back to `en1`…`en3`).
4. Safari is launched on the paired device via `xcrun devicectl device process launch --device <name> com.apple.mobilesafari http://<mac-ip>:<port>/<slug>.html`.

Prerequisites:

- The device must be paired in Xcode (`xcrun devicectl list devices` should show it as `available`).
- Developer Mode must be enabled on the device (Settings → Privacy & Security → Developer Mode).
- The device and Mac must be on the same Wi-Fi network.
- Xcode Command Line Tools must be installed (provides `xcrun devicectl`).

Finding the device name: run `xcrun devicectl list devices` — the `Name` column is what you pass to `--device`. The name can include spaces; quote it (e.g. `--device "Ben's iPad"`).

Pick the device name from the user's phrasing: "my phone" → their iPhone; "my iPad" → the iPad. If ambiguous and multiple devices are paired, ask.

### Stopping the LAN server

The server stays alive in the background to make subsequent runs snappy:

```bash
python3 ~/.claude/skills/visual-walkthrough/scripts/build_walkthrough.py --stop-server
```

### Privacy note on LAN exposure

The background server binds to `0.0.0.0`, so anything in `~/.diagrams/` is browsable by any device on the local network for as long as the server runs. Everything in that directory is walkthrough output you generated anyway — it shouldn't contain secrets — but if a walkthrough references sensitive material, stop the server (`--stop-server`) when you're done, or use `--out-dir` to route a specific walkthrough elsewhere.

## Enrich the markdown first, if diagrams would clearly help

The walkthrough renders the markdown as-is. If the source has ` ```mermaid ` fences, you'll see real diagrams. If the source is pure prose and the content is clearly diagram-shaped (architecture, call flows, state lifecycles, data models, phases), **edit the source markdown first to add Mermaid blocks** — the walkthrough becomes dramatically more useful, and the improvement persists in the file for anyone reading it later.

Match the diagram type to the content:

| Diagram syntax | Best for |
|---|---|
| `flowchart LR` / `flowchart TB` | architecture, component graphs, pipeline stages, "what connects to what" |
| `sequenceDiagram` | call flows, request/response timelines, "before vs after" of a refactor |
| `classDiagram` | protocol shapes, type hierarchies, dependency relationships |
| `stateDiagram-v2` | lifecycles, FSMs, actor state transitions |
| `erDiagram` | schemas, data models |
| `mindmap` | taxonomies, related-concepts maps |
| `timeline` | phased rollouts, release history, roadmap |
| `gitGraph` | branching strategies |

Mermaid syntax reference: https://mermaid.js.org/intro/ — cite this when composing a diagram you're unsure about.

If the user has asked you not to touch the source file, write an enriched copy (e.g., `<name>.walkthrough.md` alongside it) and render that instead. Offer this before editing in place when ownership of the source is ambiguous.

## After building

Report:

- The output path (e.g., `/Users/.../diagrams/phase11-crop-analysis.html`).
- A one-sentence summary: section count, diagram count, and anything worth pointing out (e.g., "before/after sequence diagrams on the call flow, and an unlocks-downstream flowchart at the end").

Don't dump the HTML into the conversation.

## Why this shape

- **Browser-side rendering** keeps the Python step trivial — it's just templating. marked.js parses the markdown and mermaid.js renders the diagram blocks. No Python markdown library dependency to install.
- **Single self-contained HTML** means it survives being moved, emailed, or checked into a repo. Only requirement is network access for the two CDN scripts.
- **`~/.diagrams/` as output dir** gives a stable, hidden-home location you can re-visit without cluttering the project tree. Previous walkthroughs accumulate there; delete at will.

## Troubleshooting

- **Safari opens but the page is blank** — the markdown likely contains a literal `</script>`. The build script already escapes this (`escape_for_script_block`); if a new edge case slips through, reproduce with the browser console open and extend the escape.
- **A Mermaid block shows raw text instead of a diagram** — syntax error inside that block. Open the browser devtools console for the Mermaid error message, then consult https://mermaid.js.org/intro/ for the correct syntax.
- **CDN blocked / offline** — the page needs network for `cdn.jsdelivr.net` (marked.js and mermaid.js). Vendoring locally is a future enhancement; for now, expect network access.
- **Python 3 missing** — the script uses only stdlib, but `python3` must be on PATH. On macOS it ships with the Xcode Command Line Tools.
- **Output doesn't match a recent source edit** — the script overwrites on each run. Re-run after editing; refresh Safari.

## File layout

```
visual-walkthrough/
├── SKILL.md                        (this file)
├── scripts/
│   └── build_walkthrough.py        (reads md, injects into template, writes HTML, opens Safari)
└── assets/
    └── template.html               (HTML shell: marked.js + mermaid.js + CSS + scroll-spy)
```

The template is self-contained HTML — you can open it directly in a browser to sanity-check the styling. The `__TITLE__` and `__MARKDOWN__` placeholders are the only variables.
