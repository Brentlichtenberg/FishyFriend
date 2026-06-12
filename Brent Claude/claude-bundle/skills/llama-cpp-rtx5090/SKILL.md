---
name: llama-cpp-rtx5090
description: Run llama.cpp's llama-server on Ben's RTX 5090 box (Gaminator3) over SSH, hosting Unsloth Qwen3.6 GGUFs (27B dense or 35B-A3B MoE) for agentic coding. Use this skill any time the user wants to "fire up llama.cpp", "start the Qwen server", "spin up the local model", "switch to the MoE model", "stop the model", "check on the model", "check how much VRAM the server is using", "hit the local API", "update llama.cpp", "pull the latest llama.cpp", "rebuild llama.cpp for the 5090", or asks about the llama-server endpoints, context size, or quant currently loaded. Also use when the user asks a general agentic-coding question and wants to point an editor/agent at a local OpenAI-compatible endpoint. Delegates SSH plumbing details to the `train-on-rtx5090` skill but owns everything llama.cpp / llama-server / Qwen3.6-specific.
---

# llama-cpp-rtx5090

Serve Qwen3.6-27B on Ben's home RTX 5090 via llama.cpp's `llama-server`, from this Mac, over SSH. The Mac is the controller; the PC (`Gaminator3`, 32 GiB VRAM) is the worker. This skill is about the **llama.cpp layer** — connection plumbing is covered in the `train-on-rtx5090` skill, load it alongside this one when you need SSH/rsync/cmd-vs-PowerShell details.

## Connection cheat sheet (from train-on-rtx5090)

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" "<command>"
```

Default remote shell is `cmd.exe`. Chain with `&`/`&&`, not `;`. Activate Python tools via PowerShell wrapper when needed:

```
powershell -NoProfile -Command "& 'C:\Users\bbyrn\PhoneVisionApps\venv\Scripts\Activate.ps1'; <cmd>"
```

GPU: **RTX 5090, 32607 MiB VRAM** (Blackwell, compute capability `sm_120`). Keep ~1 GiB free as headroom.

## Filesystem layout on the PC

Standardize on these paths — scripts and snippets below assume them.

| Path | Purpose |
|------|---------|
| `C:\git\llama.cpp\` | Git checkout of `ggml-org/llama.cpp` (this skill owns this location — supersedes anything already there) |
| `C:\git\llama.cpp\build\bin\Release\llama-server.exe` | Server binary (MSVC Release build) |
| `C:\models\Qwen3.6-27B-GGUF\` | Downloaded GGUF from `unsloth/Qwen3.6-27B-GGUF` — **Q6_K only** |
| `C:\models\Qwen3.6-35B-A3B-GGUF\` | Downloaded GGUF from `unsloth/Qwen3.6-35B-A3B-GGUF` — **UD-Q4_K_XL only** (MoE alt) |
| `C:\logs\llama\` | Server stdout/stderr logs, timestamped |

Create the sibling dirs once (the llama.cpp dir comes from `git clone`):

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" ^
  "mkdir C:\git 2>nul & mkdir C:\models 2>nul & mkdir C:\logs\llama 2>nul & echo done"
```

## Building llama.cpp from source (first time and refresh)

### Why build from source instead of a release

llama.cpp ships features fast. `--fit`, `--jinja` with new tool-call parsers, reasoning-format extraction, and Blackwell-specific kernel fixes all land in the main branch weeks before any tagged release. Always build from `master`.

### The RTX 5090 / Blackwell gotcha (read before building)

Blackwell (sm_120) is only stable on **CUDA 12.8**. Building with CUDA 13.x causes the MMQ (Matrix Multiply Quantized) kernels to segfault on the 5090. The PC should have `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8` installed; verify before building:

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" ^
  "dir \"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin\nvcc.exe\""
```

If missing, install CUDA 12.8 from NVIDIA's archive before proceeding. The OpenSSH session on Ben's box runs at **High Mandatory Level** (elevated enough to install), so the full install is fully scriptable — no user interaction at the PC required:

```bash
# Download local installer (~3.3 GB)
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"\$ProgressPreference='SilentlyContinue'; New-Item -ItemType Directory C:\\installers -Force | Out-Null; Invoke-WebRequest -Uri 'https://developer.download.nvidia.com/compute/cuda/12.8.1/local_installers/cuda_12.8.1_572.61_windows.exe' -OutFile C:\\installers\\cuda_12.8.1_windows.exe -UseBasicParsing\""

# Silent install — toolkit components only, no driver (existing driver is ≥ 572.x)
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"\$p = Start-Process -FilePath 'C:\\installers\\cuda_12.8.1_windows.exe' -ArgumentList '-s','nvcc_12.8','cudart_12.8','cublas_12.8','cublas_dev_12.8','thrust_12.8','visual_studio_integration_12.8' -PassThru -Wait; \$p.ExitCode\""
```

Important: the silent installer **does not prepend 12.8 to system PATH** — CUDA 13.x (if also installed) stays ahead on PATH. That's fine for the build (we pass `-DCUDAToolkit_ROOT=...v12.8` to cmake), but at **runtime** the llama-server process needs the 12.8 bin dir prepended so `cudart64_12.dll` resolves to the 12.8 copy. The launch script in the spin-up section handles that.

### First-time clone + build

This skill owns `C:\git\llama.cpp`. If something is already there, move it aside (or delete) before cloning — the build commands assume a fresh checkout from `ggml-org/llama.cpp`.

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"\$ErrorActionPreference='Stop'; if (Test-Path 'C:\\git\\llama.cpp') { Rename-Item 'C:\\git\\llama.cpp' ('llama.cpp.bak-' + (Get-Date -Format yyyyMMddHHmmss)) }; cd C:\\git; git clone https://github.com/ggml-org/llama.cpp.git; cd llama.cpp; cmake -B build -DGGML_CUDA=ON -DGGML_CUDA_FORCE_CUBLAS=OFF -DGGML_CUDA_FA_ALL_QUANTS=ON -DCMAKE_CUDA_ARCHITECTURES=120 -DCMAKE_BUILD_TYPE=Release -DCUDAToolkit_ROOT='C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8'; cmake --build build --config Release -j\""
```

Uses Visual Studio's MSVC toolchain (already on the box — it ships with CUDA). Ninja is faster but MSVC is what CUDA wires up by default on Windows, so stick with it.

Key flags and why:
- `-DCMAKE_CUDA_ARCHITECTURES=120` — compile kernels for `sm_120` only. Faster builds, no dead code for older GPUs.
- `-DGGML_CUDA_FORCE_CUBLAS=OFF` — enable MMQ (Matrix Multiply Quantized) kernels. Significantly faster than cuBLAS on Blackwell when they work, which they do on CUDA 12.8. If this is accidentally left `ON` in the CMake cache from a prior build, MMQ stays disabled — that's the "5x performance pitfall" on the 5090.
- `-DGGML_CUDA_FA_ALL_QUANTS=ON` — compile flash-attention kernels for every K/V quant combination, including `q8_0 × q8_0`. Without this, quantized KV cache silently falls back to slow paths (or fails to start). Required for the runtime flags below.
- `-DCUDAToolkit_ROOT=...v12.8` — force CUDA 12.8 even if 13.x is also installed and earlier on PATH.

Expected build time: **15–25 minutes** the first time. Run in background; tail the output afterward.

### Keeping it up to date

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"\$ErrorActionPreference='Stop'; cd C:\\git\\llama.cpp; git fetch; \$behind = (git rev-list HEAD..origin/master --count); if (\$behind -eq 0) { 'already up to date' } else { git pull; cmake --build build --config Release -j; 'rebuilt' }\""
```

Incremental rebuilds take **1–5 minutes** unless a header changed. If you pulled a PR that touched ggml-cuda, expect a full rebuild.

### Verifying the build works

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" ^
  "C:\git\llama.cpp\build\bin\Release\llama-server.exe --version"
```

You should see a commit hash, the CUDA version it was built against, and `ggml_cuda_init: found 1 CUDA devices: ... NVIDIA GeForce RTX 5090, compute capability 12.0`.

## Model options

Two models, same pipeline. Pick one based on what the session needs. Both are downloaded with the Hugging Face CLI (`hf`, successor to the deprecated `huggingface-cli`) from the existing PhoneVisionApps venv. Pull only the specific quant listed — don't grab other sizes "just in case," they're 15–30 GiB each and clutter the disk.

### Option A (default): Qwen3.6-27B dense — Q6_K

~27B dense params. Strong all-around coding model; the default choice.

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"& 'C:\\Users\\bbyrn\\PhoneVisionApps\\venv\\Scripts\\Activate.ps1'; hf download unsloth/Qwen3.6-27B-GGUF --include 'Qwen3.6-27B-Q6_K.gguf' --local-dir C:\\models\\Qwen3.6-27B-GGUF\""
```

Expect **~22.5 GiB** download.

### Option B: Qwen3.6-35B-A3B MoE — UD-Q4_K_XL

Mixture-of-Experts: 35B total params, **3B active per token** (8 routed + 1 shared out of 256 experts). Benchmarked at **73.4% SWE-bench Verified / 49.5% SWE-bench Pro / 51.5% Terminal-Bench 2.0** — a serious agentic-coding model. Decode is fast (only 3B params touched per token) even though the full 35B must be resident.

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"& 'C:\\Users\\bbyrn\\PhoneVisionApps\\venv\\Scripts\\Activate.ps1'; hf download unsloth/Qwen3.6-35B-A3B-GGUF --include '*UD-Q4_K_XL*.gguf' --local-dir C:\\models\\Qwen3.6-35B-A3B-GGUF\""
```

Expect **~22.4 GiB** download.

### Verify after download

Capture the exact filename to use as `--model`:

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" ^
  "dir C:\models\Qwen3.6-27B-GGUF & dir C:\models\Qwen3.6-35B-A3B-GGUF 2>nul"
```

If split (`*-00001-of-000NN.gguf`), point `--model` at part 1 — llama-server loads the rest automatically. If single, point at the `.gguf` directly.

## Quant choices and why

Same decision rule for both models: **pick the highest-quality quant whose weights + q8_0 KV + flash-attn kernels leave ≥ 64k usable context on a 32 GiB 5090.** That's where agentic coding wants to live (long prompts, tool-call chains, multi-file context). `--fit on` at startup sizes the actual context against free VRAM; always read the startup log for what it chose.

### 27B dense → `Q6_K` (22.5 GiB)

Weights at 22.5 GiB leave ~8 GiB for KV + overhead → **~64–96k usable context** with q8_0 KV. Why not higher:
- **Q8_0 / UD-Q8_K_XL / BF16** don't leave enough room for useful context.
- **UD-Q6_K_XL** (25.6 GiB) is marginally higher quality but cuts context to ~24–40k — not worth it.
- **Q5 / Q4** free VRAM but the quality dropoff on dense 27B in tool-call fidelity (nested JSON, multi-turn) is real.

### 35B-A3B MoE → `UD-Q4_K_XL` (22.4 GiB)

Weights at 22.4 GiB leave ~8 GiB for KV + overhead → **~64–96k usable context**, same envelope as the 27B. Why Q4 is fine here:
- **MoE models tolerate lower bit widths much better than dense** — error averages across the 8 routed experts per token, so per-expert quantization noise gets smoothed out. Q4-XL on a 256-expert MoE is ~quality-equivalent to Q5-Q6 on a dense model.
- **UD-Q5 / UD-Q6** (24.9–31.8 GiB) starve the KV cache — you'd get ≤ 16k context, which defeats the point of switching to a model with this much capacity.
- **Unsloth's `UD-` dynamic quants** calibrate bit allocation per-layer against a dataset; at the same nominal size they score slightly higher than stock `Q4_K_M`. `UD-Q4_K_XL` is the sweet spot of the set.
- **`MXFP4_MOE` (21.7 GiB)** is a candidate — an MoE-specific 4-bit format — but it's newer and less battle-tested. Start with `UD-Q4_K_XL`; switch to MXFP4_MOE only if you want to benchmark.

### Why keep the MoE fully on GPU (not `--n-cpu-moe`)

llama.cpp has `--n-cpu-moe N` / `--override-tensor exps=CPU` for offloading expert weights to system RAM. On multi-GPU or GPU-poor systems, that's how you run bigger models. **We don't need it here** — UD-Q4_K_XL fits fully on the 5090. Keeping experts on-GPU is strictly faster (VRAM bandwidth ~1.8 TB/s vs RAM's ~80 GB/s). If you ever want to try the larger UD-Q6 or UD-Q8 quants, *then* offload is the lever — but decode will drop from ~60+ tok/s to ~5–10 tok/s, so it's rarely worth it for interactive coding.

## Spinning up the server

Launch via a PowerShell script on the PC wrapped in a **Windows Scheduled Task** — that's the only robust way to detach the server from the SSH session. Three reasons the obvious alternatives don't work:

1. **`Start-Process -RedirectStandardOutput ...` dies when SSH disconnects.** The redirected file handles are held by the parent PowerShell; when SSH closes, the parent exits and OpenSSH's session teardown kills the whole process tree (default `CloseChildProcesses=1`). You get an empty log file and a gone server.
2. **Inline `powershell -Command "..."` through cmd → ssh → Mac bash is a quoting bloodbath.** Four shells worth of escaping rules collide on backticks, `$env:`, and the inner ArgumentList array. Every attempt fell over somewhere.
3. **Scheduled Task runs under a registered principal**, not under your SSH session, so the server keeps running after you disconnect. It's also trivially restartable with `Start-ScheduledTask`.

### Step 1 — put the launch script on the PC

**Naming convention.** Per-model launch scripts and Scheduled Tasks both encode the full identity: Qwen version, parameter count, MoE/dense, and quant. This makes "what is currently running" obvious from `Get-ScheduledTask` or `Get-ChildItem C:\scripts\*.ps1` without opening files. Current names:

| Model | Script | Scheduled Task |
|-------|--------|----------------|
| Qwen3.6 27B dense, Q6_K | `C:\scripts\start-qwen3.6-27b-q6_k.ps1` | `LlamaServerQwen3.6-27B-Q6_K` |
| Qwen3.6 35B-A3B MoE, UD-Q4_K_XL | `C:\scripts\start-qwen3.6-35b-a3b-ud-q4_k_xl.ps1` | `LlamaServerQwen3.6-35B-A3B-UD-Q4_K_XL` |

If you change the quant for a model, **rename the script and re-register the task** — don't reuse a name with a different quant inside.

The script does three things: prepend the CUDA 12.8 bin dir to PATH so `cudart64_12.dll` et al. resolve, build the argument list, and invoke `llama-server.exe` with stdout/stderr redirected to timestamped logs.

Copy it up from the Mac with `scp` (avoids the heredoc mess):

```bash
# Mac-side: write /tmp/start-qwen3.6-27b-q6_k.ps1 with the contents shown below, then:
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"New-Item -ItemType Directory C:\\scripts -Force | Out-Null\""
scp -i ~/.ssh/id_ed25519_rtx5090 /tmp/start-qwen3.6-27b-q6_k.ps1 \
  "brentlichtenberg@gmail.com@192.168.1.29:C:/scripts/start-qwen3.6-27b-q6_k.ps1"
```

Script contents (`start-qwen3.6-27b-q6_k.ps1`) — only the `--model` path and `--alias` change between the two models:

```powershell
$env:PATH = 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin;' + $env:PATH
$ts = Get-Date -Format yyyyMMdd-HHmmss
$log = "C:\logs\llama\server-$ts.log"
$err = "C:\logs\llama\server-$ts.err.log"
& 'C:\git\llama.cpp\build\bin\Release\llama-server.exe' `
    --model 'C:\models\Qwen3.6-27B-GGUF\Qwen3.6-27B-Q6_K.gguf' `
    --alias qwen3.6-27b `
    --host 0.0.0.0 --port 8080 `
    --n-gpu-layers auto --fit on --fit-ctx 65536 `
    --cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on `
    --batch-size 4096 --ubatch-size 2048 `
    --parallel 1 --cont-batching --no-mmap `
    --jinja --reasoning-format deepseek --reasoning-budget -1 `
    --temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 `
    1> $log 2> $err
```

Why the CUDA 12.8 PATH prepend: the toolkit silent install doesn't register itself on system PATH (13.2 is ahead of it from a prior install). Without this line, `llama-server.exe` starts, prints nothing, and vanishes — it can't resolve `cudart64_12.dll`. Set it in the script rather than mutating system env, so a future CUDA 13.x side-install can coexist.

### Vision (multimodal) — load mmproj alongside the main GGUF

**Qwen3.6-27B and 35B-A3B are both natively multimodal** (text +
image + video). To enable vision, download the mmproj projector
file from the same Unsloth GGUF repo and pass `--mmproj` to
`llama-server`. Without `--mmproj`, the server loads text-only —
which is fine for coding, but means you're silently leaving vision
on the table when the user might want it.

Download the mmproj (one-time, alongside the model download):

```
ssh Gaminator3 ^
  "powershell -NoProfile -Command \"& 'C:\\Users\\bbyrn\\PhoneVisionApps\\venv\\Scripts\\Activate.ps1'; hf download unsloth/Qwen3.6-27B-GGUF --include 'mmproj*.gguf' --local-dir C:\\models\\Qwen3.6-27B-GGUF\""
```

Add `--mmproj` to the launch script (after `--model`):

```powershell
& 'C:\git\llama.cpp\build\bin\Release\llama-server.exe' `
    --model  'C:\models\Qwen3.6-27B-GGUF\Qwen3.6-27B-Q6_K.gguf' `
    --mmproj 'C:\models\Qwen3.6-27B-GGUF\mmproj-F16.gguf' `
    --alias qwen3.6-27b `
    ...
```

Endpoint stays OpenAI-compatible. Send images via `image_url` in
the message content — either an `http(s)://` URL the server can
reach or a `data:image/png;base64,...` data URL. Vision tokens
count against `--ctx-size` (figure ~256–1024 vision tokens per
image depending on resolution).

If you spin up a vision-enabled instance for one task, **you can
keep the same instance for text-only tasks** — there's no
text-only mode penalty. The only cost is ~1–2 GB extra VRAM for
the projector and extra prefill time on requests that include
images.

To verify vision is loaded after spin-up: hit `/v1/models` and
check the response includes vision capabilities, or send a tiny
image with a "describe this" prompt and confirm a non-empty
response. Pure-text requests against a `--mmproj`-loaded server
work normally.

---

**For the 35B-A3B MoE:** same script with two lines swapped:
```
--model 'C:\models\Qwen3.6-35B-A3B-GGUF\Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf' `
--alias qwen3.6-35b-a3b `
```
(Replace the filename with whatever `dir` reported after download — Unsloth occasionally splits larger files.)

### Step 2 — register and start the Scheduled Task

One-time registration (or `-Force` to overwrite on re-register):

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"\$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\\scripts\\start-qwen3.6-27b-q6_k.ps1'; \$principal = New-ScheduledTaskPrincipal -UserId \$env:USERNAME -LogonType S4U -RunLevel Limited; \$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 30); Register-ScheduledTask -TaskName 'LlamaServerQwen3.6-27B-Q6_K' -Action \$action -Principal \$principal -Settings \$settings -Force | Out-Null; Start-ScheduledTask -TaskName 'LlamaServerQwen3.6-27B-Q6_K'\""
```

On subsequent starts (already registered) — just:
```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"Start-ScheduledTask -TaskName 'LlamaServerQwen3.6-27B-Q6_K'\""
```

Task settings chosen:
- `-LogonType S4U` — "Service For User," runs without storing a password. Works for non-network actions, which is what we need.
- `-RunLevel Limited` — no elevation required; the server doesn't need admin.
- `-AllowStartIfOnBatteries -DontStopIfGoingOnBatteries` — desktop, but explicit against Windows auto-killing long tasks.
- `-ExecutionTimeLimit 30 days` — default is 72 hours, which silently kills long-running sessions.

### Step 3 — open the firewall for LAN access (one time)

Windows Firewall blocks inbound 8080 by default on `Public` and even on `Private` from anything off-localhost. Add a scoped rule so the Mac can hit it but the wider internet can't:

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"New-NetFirewallRule -DisplayName 'llama-server 8080 LAN' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080 -RemoteAddress 192.168.1.0/24 -Profile Private,Domain | Out-Null\""
```

Rule is persisted — only needs to be added once per fresh Windows install. Scoped to the home subnet, so WAN-side traffic still can't reach the server even if the port were somehow forwarded.

### Why each flag (the 5090 optimization rationale)

**Placement & resource fit**
- `--host 0.0.0.0` — listen on the LAN so the Mac can hit it at `http://192.168.1.29:8080`. LAN only; the PC is not publicly reachable.
- `--n-gpu-layers auto` — offload all layers that fit. For a 27B on a 5090 this ends up being all of them.
- `--fit on --fit-ctx 65536` — lets llama.cpp size the actual context against VRAM but refuses to start if it can't give ≥ 64k. Catches mis-sized runs instead of silently loading 4k.
- `--no-mmap` — with every layer on the GPU there's no reason to keep a second copy of weights memory-mapped in RAM. Skipping the mmap path cuts cold-start time and halves RAM footprint on the PC.

**KV cache (the single biggest memory lever)**
- `--cache-type-k q8_0 --cache-type-v q8_0` — 8-bit quantized KV cache, roughly halves KV memory vs f16 for negligible quality loss on Qwen3.6. This is what turns "~32k ctx" into "~64–96k ctx."
- `--flash-attn on` — **required** for quantized KV; also faster for long contexts on its own. Requires the build to have `GGML_CUDA_FA_ALL_QUANTS=ON` (see build section) — otherwise the q8_0 × q8_0 path isn't compiled in.

**Prefill throughput (this is what makes the 5090 feel fast on long prompts)**
- `--batch-size 4096 --ubatch-size 2048` — default is `2048 / 512`, which underutilizes the 5090's memory bandwidth. Raising both pushes prefill from ~1500 tok/s to ~3000+ tok/s on long (≥8k) prompts, where agentic coding spends most of its time. `ubatch` is what actually runs through the kernels in one pass; `batch` is the scheduling chunk.
- `--parallel 1` — single slot. Dedicates the full context budget to one request, which is what you want for a single-user agent. Raise only if you want to run multiple editor sessions against the same server (splits the KV).
- `--cont-batching` — continuous batching across in-flight requests. On by default in `llama-server`, but explicit documents intent and survives future default changes.

**Chat format & reasoning (tool-use correctness)**
- `--jinja` — use the Jinja chat template embedded in the GGUF. Qwen3.6's template declares tools correctly, so OpenAI-compat tool calls "just work" through `/v1/chat/completions`.
- `--reasoning-format deepseek` — strips `<think>...</think>` blocks out of `content` and surfaces them in `reasoning_content`. Editors that speak the OpenAI reasoning format render them separately; clients that don't just see clean `content`.
- `--reasoning-budget -1` — no cap on thinking tokens. Agentic debugging runs long; capping hurts.
- `--alias qwen3.6-27b` — what the server reports in `/v1/models`. Lets clients pin the `model` field cleanly.

**Sampler (Qwen's official thinking-mode recipe for precise coding)**
- `--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0`. Do not use greedy decoding (`temp 0`); Qwen's docs explicitly warn it degrades thinking-mode output. For instruct mode (thinking disabled per-request), switch at the server level to `--temp 0.7 --top-p 0.80 --top-k 20 --presence-penalty 1.5`.

### Waiting for it to come up

First load takes **30–90 seconds** (mmap + graph build + warmup). Poll `/health`:

```
until ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "curl -fsS http://localhost:8080/health" 2>/dev/null | grep -q '"status":"ok"'; do sleep 5; done
echo "server is up"
```

Then confirm the actual context size it settled on:

```
curl -fsS http://192.168.1.29:8080/props | python3 -c 'import sys, json; p=json.load(sys.stdin); print("ctx:", p.get("default_generation_settings",{}).get("n_ctx"), "model:", p.get("model_path"))'
```

If `ctx` came back lower than `--fit-ctx`, the process won't have started — `--fit-ctx` is a floor. Check the latest error log with `Get-Content (Get-ChildItem C:\logs\llama\server-*.err.log | Sort LastWriteTime -Desc | Select -First 1).FullName -Tail 100`.

## Spinning down

Stop the Scheduled Task — that's the clean way, and it lets `Start-ScheduledTask` bring the server back without re-registering:

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"Stop-ScheduledTask -TaskName 'LlamaServerQwen3.6-27B-Q6_K' -ErrorAction SilentlyContinue; Stop-Process -Name llama-server -Force -ErrorAction SilentlyContinue\""
```

`Stop-ScheduledTask` signals the task engine; the belt-and-suspenders `Stop-Process` covers the edge case where llama-server ignored the signal (rare on Windows, but graphs loaded on the GPU sometimes linger).

Verify VRAM freed:

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader"
```

`memory.used` should drop back to a few hundred MiB (desktop compositor + idle driver).

## Introspecting a running server

The server exposes a lot — you rarely need to log into the box to answer "how is it running?"

### Health & load state

```
curl -fsS http://192.168.1.29:8080/health
```
Returns `{"status":"ok"}` when ready, or `503` with `loading_model` while mmap/warmup is happening.

### What's actually loaded (ctx size, chat template, model path, samplers)

```
curl -fsS http://192.168.1.29:8080/props | python3 -m json.tool
```
This is the source of truth for "what quant / what context / what template is running." `default_generation_settings.n_ctx` is the effective context. `chat_template` shows the Jinja template in use.

### Live slot state (what it's processing right now)

```
curl -fsS http://192.168.1.29:8080/slots | python3 -m json.tool
```
One entry per parallel slot (1 by default). Shows current `state` (`IDLE` / `PROCESSING_PROMPT` / `GENERATING`), tokens processed, prompt length, generation length. Useful to tell whether a stuck client is waiting on the server or on something else.

### Prometheus-style metrics

```
curl -fsS http://192.168.1.29:8080/metrics
```
Cumulative counters: `llamacpp:prompt_tokens_total`, `llamacpp:tokens_predicted_total`, `llamacpp:kv_cache_usage_ratio`, etc. Useful for long-running inspection.

### GPU memory usage on the box

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu,temperature.gpu,power.draw --format=csv,noheader"
```
Expect `memory.used` ≈ weights + KV + a bit of overhead, roughly 24–30 GiB for Q6_K with 64k q8_0 KV.

### Process + uptime

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"Get-Process llama-server | Select-Object Id, StartTime, CPU, PM, NPM\""
```

### Tail the log

```
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" \
  "powershell -NoProfile -Command \"Get-Content (Get-ChildItem C:\\logs\\llama\\server-*.log | Sort LastWriteTime -Desc | Select -First 1).FullName -Tail 100\""
```

## Using the server from the Mac

### OpenAI-compatible endpoints

Base URL: `http://192.168.1.29:8080/v1`

| Endpoint | Purpose |
|----------|---------|
| `POST /v1/chat/completions` | Primary for agentic coding. Supports `tools`, `tool_choice`, and returns `reasoning_content` when `--reasoning-format deepseek`. |
| `POST /v1/completions` | Legacy text completion. |
| `POST /v1/embeddings` | Only if you started the server with `--embedding`; off by default for this model. |
| `GET  /v1/models` | Reports the loaded model ID. |

Point any OpenAI-compatible client at that base URL. Most accept a dummy API key — pass `OPENAI_API_KEY=anything`.

### llama.cpp-native endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST /completion` | Native streaming completion with more knobs than OpenAI format exposes (grammars, per-request slot id, etc.). |
| `POST /tokenize`, `POST /detokenize` | Exposes the model's BPE. |
| `POST /apply-template` | Runs a messages array through the Jinja template and returns the resulting string — invaluable for debugging "why is my tool call not being recognized." |
| `GET  /props` | Loaded config snapshot (see Introspecting). |
| `GET  /slots` | Slot state (see Introspecting). |
| `GET  /metrics` | Prometheus metrics (see Introspecting). |
| `GET  /health` | Liveness (see Introspecting). |

### Port-forward from Mac (optional)

If you want `http://localhost:8080` to hit the 5090 — convenient for tools that hard-code localhost:

```
ssh -i ~/.ssh/id_ed25519_rtx5090 -N -L 8080:localhost:8080 "brentlichtenberg@gmail.com@192.168.1.29"
```

Run with `run_in_background: true`; kill when done. Direct LAN access is usually fine though.

## Sampler presets for agentic coding

**Default to thinking mode for every request.** The local-llm skill spells out why (Rule #0): instruct mode silently degraded our Board Control bakes — rhythm-template residue, length-following collapse, mode-collapse on creative tasks. The "speed win" of instruct gets cancelled by retries; the *consistency* win of thinking compounds. Always thinking unless you have a specific reason not to, and document the reason at the call site.

The server-level `--temp`/`--top-p`/etc. become defaults; clients override per-request.

### Thinking mode (default — every request unless explicitly noted)

**Precise-coding thinking** (structured output, tool calls, ratings, JSON):
```
--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0
```

**General-thinking** (creative prose, open-ended writing) — override per-request:
```
--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0
```

Per-checkpoint adjustments (always fetch the current Unsloth recipe — these change between point releases):
- **Qwen3.6-35B-A3B** general-thinking adds `--presence-penalty 1.5`
- **Gemma 4 26B-A4B** uses `--top-k 64` and supports `--image-min-tokens 70..1120`

Server emits `<think>...</think>` blocks; with `--reasoning-format deepseek` they're split into `reasoning_content`. Do **not** use greedy decoding (temperature = 0) — Qwen's docs explicitly warn it causes performance degradation in thinking mode.

**`max_tokens` budgets must cover both `<think>` and visible output.** Under-budgeting fails silently with empty visible output (thinking eats the budget; the model emits nothing visible). Rough floors:
- Single-integer rating / classification: ≥ 4000
- Bounded prose (60-200 visible tokens): ≥ 8000-12000
- Long-form prose (~500-1000 visible): ≥ 16000-32000
- Vision longform: ≥ 32000

For agentic workflows that feed thinking back across turns (some editor agents), pass `{"preserve_thinking": true}` per request — keeps prior reasoning in the KV cache instead of re-deriving it.

### Instruct / non-thinking mode (rare; explicit opt-in only)

If you need it (sub-1B utility models, A/B comparisons, latency-pinned UI calls), pass it explicitly:
```json
{
  "model": "qwen3.6-27b",
  "messages": [...],
  "chat_template_kwargs": {"enable_thinking": false}
}
```

Server-level instruct sampler (only relevant if you launched in instruct mode):
```
--temp 0.7 --top-p 0.80 --top-k 20 --min-p 0.0 --presence-penalty 1.5
```

**Always comment the call site explaining why thinking is disabled.** A bare `enable_thinking: False` with no justification is a bug waiting to bite a future agent.

## Things that have bitten before (or will)

- **Building with CUDA 13.x** — MMQ kernels segfault on Blackwell. Force 12.8 via `-DCUDAToolkit_ROOT`. If you see `CUDA error: invalid resource handle` at first token, this is the cause.
- **`GGML_CUDA_FORCE_CUBLAS=ON` leaking in from a prior build** — disables MMQ kernels and costs roughly 5x on Blackwell. After any re-configure, confirm by grepping the CMake cache: `Select-String GGML_CUDA_FORCE_CUBLAS C:\git\llama.cpp\build\CMakeCache.txt` should show `=OFF`.
- **Forgetting `GGML_CUDA_FA_ALL_QUANTS=ON` at build time** — then `--cache-type-k q8_0 --cache-type-v q8_0 --flash-attn on` at runtime either refuses to start or silently falls back. Rebuild with the flag; it's cheap at configure time and removes a whole class of confusing runtime errors.
- **Forgetting `--flash-attn on` with quantized KV cache** — same outcome as above. Always pair them.
- **Passing `--ctx-size` and expecting `--fit` to shrink it** — `--fit` only *adjusts unset arguments*. An explicit `--ctx-size` wins, and the server will OOM at runtime if it doesn't actually fit. Use `--fit-ctx` (floor) to constrain instead.
- **Multi-part GGUFs** — point `--model` at `*-00001-of-000NN.gguf`; llama-server loads the rest automatically. Point at part 2 and it loads and runs but produces garbage.
- **`--ubatch-size` larger than `--batch-size`** — won't start. The ubatch must divide the batch. The `4096 / 2048` pairing here is deliberate.
- **Second server on top of the first** — only 32 GiB in the box. A second `llama-server` won't fit; it'll start, partially load, and OOM. Always stop the running one first. Same rule applies when swapping between the 27B and the 35B-A3B: stop → verify VRAM freed → start the other one.
- **Thinking the MoE needs special runtime flags to "activate experts"** — it doesn't. llama.cpp dispatches experts per-token automatically from the GGUF's router weights. The only MoE-specific knobs (`--n-cpu-moe`, `--override-tensor exps=CPU`) are for *offloading* experts to RAM when the model doesn't fit — not for enabling them. Leave those off for this setup.
- **Windows sleep** — covered in `train-on-rtx5090`. A sleeping disk means the KV cache page-in stalls; set Power Options to Never sleep.
- **LAN-only assumption** — `--host 0.0.0.0` makes the server reachable on the home network only because the PC isn't port-forwarded. Do not expose 8080 publicly; llama-server has no auth by default.
- **`huggingface-cli` is deprecated** — the new CLI is `hf` (still from the same package). Old snippets that call `huggingface-cli download ...` print a deprecation error and exit 1. Always use `hf download ...`.
- **Glob `*Q6_K*.gguf` matches *two* files** — the stock `Qwen3.6-27B-Q6_K.gguf` (22.5 GiB) *and* Unsloth's `Qwen3.6-27B-UD-Q6_K_XL.gguf` (25.6 GiB). The `--include` patterns in this skill pin to exact filenames (`Qwen3.6-27B-Q6_K.gguf`) to prevent silently grabbing 48 GiB.
- **`Start-Process` + `-RedirectStandardOutput` dies on SSH disconnect** — the redirected file handles are owned by the parent PowerShell, which OpenSSH kills when the session closes. Use a Scheduled Task instead (see spin-up section). Symptom: server appears to start, log files exist but are empty, process is gone seconds later.
- **Windows Firewall blocks LAN access to 8080 by default** — the server reports `listening on 0.0.0.0:8080` and works from the PC's own localhost, but the Mac gets `connection refused`. Add the `llama-server 8080 LAN` firewall rule (see spin-up section); it's persistent.

## When to defer to another skill

- SSH/cmd.exe/PowerShell mechanics, `rsync`, general PC probing: **`train-on-rtx5090`**.
- Running llama.cpp *on iOS / macOS* (building XCFrameworks, mtmd vision): **`llama-cpp-ios`** and **`mtmd-vision`**.
- **Which model / which quant to run, what quant labels mean, what's newly released, benchmark interpretation:** **`local-llm`**. Questions like "what's the difference between Q6_K and UD-Q6_K_XL", "what's the best local coding model right now", "is there anything new from Unsloth", "can I fit a 70B on the 5090" — all answered there. This skill covers only how to *operate* the server; `local-llm` covers what to *load* into it.
- Wiring a local model into Claude Code (proxy, routing, settings.json): **`claude-local-model`**.
- Generic agentic-coding prompting advice not specific to this setup: no skill; answer directly.
