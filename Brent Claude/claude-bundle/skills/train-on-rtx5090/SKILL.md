---
name: train-on-rtx5090
description: How to run ML training jobs on Ben's home RTX 5090 box (Gaminator3) over SSH from this Mac — connection, dataset sync, kicking off jobs, streaming logs, and pulling weights back. Use this skill whenever a task involves "train on the 5090", "send this to the GPU box", "kick off a YOLO/PyTorch run on my PC", or any remote-training work where the actual GPU compute lives on the Windows machine. Also use it any time you need to probe what's installed on the PC, check disk/GPU usage there, or troubleshoot a stuck training run remotely.
---

# train-on-rtx5090

A reusable harness for shipping ML training work from this Mac to Ben's home RTX 5090 box. The Mac is the controller (orchestration, data prep, post-processing, deployment); the PC is the worker (just runs the GPU job). Frameworks change (YOLO today, maybe HF Transformers tomorrow); the connection plumbing doesn't.

## Connection facts

| Field | Value |
|-------|-------|
| Hostname | `Gaminator3` |
| LAN IP | `192.168.1.29` (home network only — no public exposure) |
| SSH user | `brentlichtenberg@gmail.com` (Microsoft account login; underlying Windows account is `bbyrn`) |
| SSH key | `~/.ssh/id_ed25519_rtx5090` (dedicated key, not the default) |
| Default shell | **`cmd.exe`** — `;` does not chain commands; use `&` (unconditional) or `&&` (on success) |
| Venv | `C:\Users\bbyrn\PhoneVisionApps\venv\Scripts\Activate.ps1` (Ultralytics 8.4.39, torch 2.11.0+cu128) |
| GPU | RTX 5090, **32607 MiB VRAM** |
| Dataset root | `C:\Datasets\` (top-level; subdirs per dataset) |
| Training output root | wherever the script writes (Ultralytics defaults to `runs\<project>\<name>\weights\`) |

## The single-command SSH idiom

Always use the dedicated key explicitly — the default key list won't include it.

```bash
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" "<command>"
```

## cmd.exe quoting gotchas (read this once, save yourself an hour)

The remote default shell is `cmd.exe`, not PowerShell or bash. Three things bite:

1. **Command separators**: `&` (unconditional), `&&` (on success), `||` (on failure). **Not** `;`.
2. **Quoting**: the local Mac shell expands `$VAR` and treats `&` as backgrounding. To pass either through unchanged, single-quote the inner command on the Mac side and double-quote on the PC side, OR escape with `\&`. Easiest: build the command in a shell variable and pass it through.
3. **Multi-line / parens**: cmd's `if (...) (...) else (...)` blocks chained with `&` sometimes swallow the rest of the line. When in doubt, run multiple `ssh` invocations instead of one chained one.

### When you actually need PowerShell (not cmd)

Activating a Python venv requires PowerShell because the activation script is `.ps1`. Wrap the whole job in a `powershell -NoProfile -Command "..."` invocation:

```bash
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"& 'C:\\Users\\bbyrn\\PhoneVisionApps\\venv\\Scripts\\Activate.ps1'; yolo version; python -c 'import torch; print(torch.__version__, torch.cuda.is_available())'\""
```

Note the doubled backslashes inside the PowerShell string — cmd consumes one level of escaping before PowerShell sees the path.

## Probing the box before you run anything

Run these first to catch surprises (missing venv, full disk, wrong torch version, GPU busy with someone else's job):

```bash
# GPU + free VRAM
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "nvidia-smi --query-gpu=name,memory.total,memory.free,utilization.gpu --format=csv,noheader"

# Disk space on the dataset drive
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "fsutil volume diskfree C:"

# Verify the venv + frameworks are still healthy
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"& 'C:\\Users\\bbyrn\\PhoneVisionApps\\venv\\Scripts\\Activate.ps1'; python -c 'import torch, ultralytics; print(torch.__version__, ultralytics.__version__, torch.cuda.is_available())'\""
```

## Syncing data up to the PC

Use `rsync` — it's resumable, deltas only, and handles big datasets gracefully. SSH from rsync needs the key path passed via `-e`.

```bash
rsync -avh --progress -e "ssh -i ~/.ssh/id_ed25519_rtx5090" \
  ~/Documents/Projects/PhoneVisionApps/Datasets/SKU-110K/ \
  "brentlichtenberg@gmail.com@192.168.1.29:/cygdrive/c/Datasets/SKU-110K/"
```

The Windows OpenSSH server understands `/cygdrive/c/...` paths because it's built on the same MSYS plumbing — much easier than escaping `C:\Datasets\...` through quoting layers.

For Ultralytics-managed dataset downloads (Open Images, COCO, etc.), often it's faster to **download directly on the PC** rather than via the Mac — saves a round trip. Trigger from the Mac, but let the PC pull from the source.

## Kicking off a long training job

Long jobs need three things: detached execution, persistent logs, and a way to check on them later without keeping the SSH tunnel open.

### Pattern A — start, walk away, check later

```bash
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"& 'C:\\Users\\bbyrn\\PhoneVisionApps\\venv\\Scripts\\Activate.ps1'; cd C:\\Users\\bbyrn\\PhoneVisionApps; Start-Process -NoNewWindow -RedirectStandardOutput logs\\train-\$(Get-Date -Format yyyyMMdd-HHmmss).log -RedirectStandardError logs\\train-err.log powershell -ArgumentList '-NoProfile','-File','scripts\\train_my_model.ps1' \""
```

Then later:
```bash
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"Get-Content C:\\Users\\bbyrn\\PhoneVisionApps\\logs\\train-*.log -Tail 50\""
```

### Pattern B — interactive with live log streaming (good for short runs)

Run with `Bash` tool's `run_in_background: true` so you can do other work while it streams:

```bash
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"& 'C:\\Users\\bbyrn\\PhoneVisionApps\\venv\\Scripts\\Activate.ps1'; cd C:\\Users\\bbyrn\\PhoneVisionApps; & '.\\scripts\\train_my_model.ps1'\""
```

### Why a `.ps1` script, not a long inline command

For anything beyond a smoke test, write the job as a PowerShell script that lives in `scripts/` and is synced to the PC. The SSH command then just invokes the script. Two reasons:

1. **Reproducibility** — the script is in version control on the Mac, synced to the PC. The exact training command is reviewable, not buried in your shell history.
2. **Error handling** — `$ErrorActionPreference = "Stop"` and explicit `throw` inside the script give you real exit codes. Inline cmd-PowerShell-bash sandwiches eat exit codes silently.

The existing `scripts/train_yolo11n_sku110k.ps1` is the template to copy from.

## Pulling results back

```bash
rsync -avh --progress -e "ssh -i ~/.ssh/id_ed25519_rtx5090" \
  "brentlichtenberg@gmail.com@192.168.1.29:/cygdrive/c/Users/bbyrn/PhoneVisionApps/runs/<project>/<name>/weights/" \
  ~/Documents/Projects/PhoneVisionApps/runs/<project>/<name>/weights/
```

Pull the entire `runs/<project>/<name>/` directory if you want training plots and metrics CSVs alongside weights.

## Killing a runaway job

```bash
# List Python processes on the PC
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "tasklist /FI \"IMAGENAME eq python.exe\""

# Kill by PID (substitute the PID from the listing above)
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "taskkill /PID <pid> /F"

# Or nuke all python processes (be sure nothing else important is running)
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "taskkill /IM python.exe /F"
```

## Things that have bitten before

- **`ssh` without `-i ~/.ssh/id_ed25519_rtx5090`** — falls back to default keys, gets denied, no useful error. Always pass the key explicitly.
- **Using `;` instead of `&`** — silently runs only the first command in cmd. Always use `&` or `&&`.
- **Forgetting venv activation** — `yolo` and `python -c "import torch"` won't work from cmd's default PATH. Always wrap in PowerShell with the activation prelude.
- **Default torch on the venv is 2.11.0+cu128, not 2.5.1** — fine for *training*. The 2.5.1 pin in scripts/README only matters for the **CoreML export step**, which runs on the Mac in a separate `.venv-yolo`. Don't try to "fix" the PC's torch.
- **Dataset drive lives on `C:`** — that's a single SSD. If you sync 50GB up and the disk fills, training fails halfway with cryptic errors. Always run `fsutil volume diskfree C:` before a large sync.
- **Battery / sleep** — the PC is a desktop, but Windows still sleeps the disk by default. If a job hangs after a few hours of idle, check Power Options on the PC (you may need to set "Never sleep" via remote PowerShell once).

## When this skill should defer to a more specific one

- For YOLO training specifically, also load the `yolo-finetune` skill — it knows our `imgsz=640`, `nms=True`, CoreML export contract, and dataset-mixing strategy. This skill handles the *transport*; that one handles the *recipe*.
- For non-ML use of the PC (gaming server, file storage), this skill doesn't apply.
