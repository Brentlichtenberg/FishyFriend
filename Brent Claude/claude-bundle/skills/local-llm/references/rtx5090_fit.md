# Fitting models on the RTX 5090

Everything here is written against Ben's 5090 box (`Gaminator3`): **32,607 MiB VRAM**, Blackwell (`sm_120`), CUDA 12.8 runtime (13.x installed but not used by llama.cpp — see the `llama-cpp-rtx5090` skill for build/runtime setup).

## 1. The VRAM budget

Total **31 GiB usable** after desktop compositor + driver overhead. Allocate like this:

```
weights        ← quantized model file, held in VRAM
KV cache       ← grows with context length × num_layers × head_dim
compute buffer ← scratch for attention / FFN (grows modestly with ubatch)
driver / misc  ← leave ~1 GiB headroom
```

Compute buffer is typically 1–2 GiB on 27–35B models with `ubatch=2048`. Driver/misc is ~800 MiB. So the usable envelope is:

**weights + KV ≈ 28 GiB.**

That is the single number to hold in your head when sizing a model.

## 2. KV cache math

KV cache size per token, in bytes (with flash attention on):

```
kv_bytes_per_token = 2 × num_layers × num_kv_heads × head_dim × kv_dtype_bytes
```

Using q8_0 KV (`--cache-type-k q8_0 --cache-type-v q8_0`) gives `kv_dtype_bytes = 1.0625` (q8_0 is 8-bit plus a per-block scale). f16 is 2.0.

Ballpark for the models we run:

| Model | Layers | KV heads | head_dim | bytes/tok (q8_0) | bytes/tok (f16) |
|---|---|---|---|---|---|
| Qwen3.6-27B dense | 64 | 8 | 128 | ~137 KiB/tok | ~256 KiB/tok |
| Qwen3.6-35B-A3B MoE | 48 | 8 | 128 | ~103 KiB/tok | ~192 KiB/tok |
| 7B (Llama / Qwen family) | 32 | 8 | 128 | ~68 KiB/tok | ~128 KiB/tok |
| 13B | 40 | 8 | 128 | ~86 KiB/tok | ~160 KiB/tok |
| 70B (typical) | 80 | 8 | 128 | ~170 KiB/tok | ~320 KiB/tok |

For 64k ctx on Qwen3.6-27B: `64000 × 137 KiB ≈ 8.4 GiB` (q8_0) vs 16.4 GiB (f16). That ~8 GiB saving is what lets q8_0 KV extend a 32k-ctx model into 64–96k territory.

**Always use q8_0 for KV on the 5090** unless you're benchmarking — the quality loss is sub-1% and the VRAM savings are enormous.

## 3. Per-model-size sweet spots

Given 28 GiB for weights + KV, here's what fits at meaningful context:

### 7B–8B models

- Fits **BF16** (~14 GiB) with ~14 GiB for KV = ~100k+ ctx.
- Or **Q8_0** (~7.5 GiB) with ~20 GiB for KV = 200k+ ctx (if the model's `n_ctx_train` allows).
- **You're not VRAM-constrained at this size** — pick the quant that gives you the most *trained* context headroom, which is usually the model's native `n_ctx_train`.

### 13B–14B

- **Q8_0** (~14 GiB) + ~14 GiB KV = ~80–100k ctx. Very comfortable.
- **Q6_K** (~11 GiB) + ~17 GiB KV = ~130k ctx.
- For agentic coding at 13B: Q8_0 is the right pick unless you need > 100k ctx.

### 20B–30B dense (e.g. Qwen3.6-27B, Codestral-22B)

- **The interesting size.** Fits up to ~Q6_K / UD-Q6_K_XL with useful context.
- **UD-Q6_K_XL** (~23 GiB for 27B) + ~5 GiB KV = ~40–64k ctx. Near-BF16 quality.
- **Q6_K** (~22 GiB) + ~6 GiB KV = ~48–72k ctx. Marginally worse quality.
- **UD-Q4_K_XL** (~16 GiB) + ~12 GiB KV = ~90–130k ctx. Quality drops but context triples.
- **IQ4_XS** (~15 GiB) + ~13 GiB KV = ~100–140k ctx.

**Rule of thumb for 27B**: pick UD-Q6_K_XL if your prompts are ≤ 48k; pick UD-Q4_K_XL if you need long context or lots of tool-call rounds.

### 30B–40B MoE (e.g. Qwen3.6-35B-A3B, Mixtral-8x7B successors)

- **Weights are total params**, not active. 35B total weights must fit even if only 3B are used per token.
- **UD-Q4_K_XL** (~22 GiB for 35B-A3B) + ~6 GiB KV (MoE KV is smaller — fewer layers) = ~64–96k ctx. This is the **default MoE pick** on the 5090.
- **MXFP4_MOE** (~21 GiB) + ~7 GiB KV = ~72–100k ctx. Slightly smaller, experimental. Worth benchmarking for prefill speed on Blackwell.
- Higher quants (UD-Q5_K_XL, UD-Q6_K_XL) fit but **starve the KV cache** — you'd end up with ≤ 16k ctx, defeating the point of a long-context model.

**MoE decode is fast**: only `active_params × bytes_per_weight` is touched per token, so a 35B-A3B at Q4 decodes like a 3B model (very fast), but the full 35B is in VRAM. This is why MoE > dense for interactive coding when both fit.

### 70B dense

- **Does not fit comfortably on a 5090.** Even IQ3_XS (~27 GiB) leaves < 1 GiB for KV = essentially no context.
- **IQ2_M / IQ2_XS** (~22–24 GiB) + tiny KV = ~8–16k ctx. Quality at IQ2 is marginal for coding.
- **Verdict**: don't serve 70B dense on this box. Pick a 30B dense or 35B-A3B MoE instead, which will beat IQ2_70B in practical use despite fewer params.

### 100B+ MoE (e.g. DeepSeek-V3 variants, Llama-4-scout if serving locally)

- **Does not fit on one 5090**, regardless of quant, for any useful context.
- If you *must* run one, CPU-offload experts (`--override-tensor exps=CPU` or `--n-cpu-moe N`) — decode drops from 60+ to 5–10 tok/s, so only worth it for overnight-batch use, not interactive.

## 4. Blackwell-specific performance notes

### CUDA 12.8 is the required runtime

llama.cpp kernels (MMQ in particular) segfault on Blackwell if compiled/linked against CUDA 13.x. The `llama-cpp-rtx5090` skill pins the build to CUDA 12.8. Never override that without benchmarking both paths — the 13.x path is ~5× slower when it doesn't outright crash.

### MMQ kernels beat cuBLAS on Blackwell

Keep `GGML_CUDA_FORCE_CUBLAS=OFF` in the build. MMQ (Matrix Multiply Quantized) has direct-from-quantized kernels that don't have to dequantize to FP16 first, which saves both bandwidth and cycles. On a 5090 this is ~1.5–2× faster than the cuBLAS path for prefill.

### Flash attention required for q8_0 KV

The `--flash-attn on` flag is mandatory with quantized KV. Without it, the q8_0-KV path either refuses to start or silently falls back to slow non-flash attention. The llama.cpp build must have `GGML_CUDA_FA_ALL_QUANTS=ON` for the q8_0 × q8_0 attention kernel to be compiled in — this is set in the existing build.

### FP4 tensor cores (Blackwell-only)

The 5090 has native FP4 Tensor Cores (the only consumer GPU that does, as of April 2026). This is exploited by the `MXFP4_MOE` GGUF format — when you load an MXFP4 model, llama.cpp dispatches to the FP4 Tensor Core path for MUL_MAT. This is the single biggest architectural advantage the 5090 has over older generations.

MXFP4 is still new (kernels landed in llama.cpp early 2026) — benchmark before relying on it for production. When it works, expect 1.3–1.8× faster prefill vs UD-Q4_K_XL.

### Prefill vs decode on Blackwell

- **Prefill is bandwidth-bound for the first few k tokens, then compute-bound on longer prompts.** The 5090's 1.8 TB/s VRAM bandwidth is ~1.4× a 4090's. For agentic coding where prompts are long (≥ 8k), the Blackwell bandwidth gain dominates.
- **Decode is almost purely memory-bound** — each token reads the full KV cache. A 5090 decodes ~1.4× faster than a 4090 at the same model size just from memory bandwidth; compute improvements don't help here.
- **With `ubatch-size=2048 batch-size=4096`** (the existing skill's defaults), prefill on a 27B Q6 is ~3000 tok/s, decode is 60–80 tok/s. Those numbers are the target — if a new model / quant is much slower, something is misconfigured.

### Ubatch / batch tuning

Default llama.cpp is `batch=2048 ubatch=512`. On Blackwell, `batch=4096 ubatch=2048` roughly doubles prefill throughput on ≥ 8k prompts. Rules:

- `ubatch` must divide `batch`.
- Higher `ubatch` uses more compute-buffer VRAM (scales linearly). On 27B this is ~1 GiB at 2048 vs ~300 MiB at 512. Usually fine; it eats into the 1 GiB headroom, so verify with `/props` after startup.
- Bumping past `ubatch=2048` hits diminishing returns — the kernels saturate the Tensor Core throughput.

## 5. Picking a model for "this task"

When the user asks "what's the best model for X on the 5090," the matrix is roughly:

| Task | Best on the 5090 (April 2026) | Why |
|---|---|---|
| Agentic coding (Claude Code / Cursor replacement) | **Qwen3.6-35B-A3B @ UD-Q4_K_XL** | Top open-weight SWE-bench Verified; MoE fast decode; fits ~80k ctx |
| Fastest quality-per-latency for chat / instructions | Qwen3.6-27B @ UD-Q6_K_XL or the MoE alternate | Qwen3.6 tops LiveBench among ≤ 35B open-weight |
| Math / reasoning | Qwen3.6-27B "thinking" mode | Dedicated thinking tokens; keep `--reasoning-budget -1` |
| Long-context (≥ 128k) | Qwen3.6 family — dense @ Q4 or MoE @ Q4 | Trained at 256k natively |
| Vision-language | Qwen3-VL-30B quants (when available) or InternVL-40B @ IQ4_XS | Best open VLMs with GGUF support |
| Sub-8B fast iteration | Qwen3-4B @ BF16 or the 8B variant at Q8 | Tight loop for tool testing |

**This list goes stale fast.** Always cross-check against the leaderboards + Unsloth's recent uploads before recommending. See `references/leaderboards.md`.

## 6. Debugging VRAM surprises

After starting a server, verify it settled where you expected:

```bash
curl -fsS http://192.168.1.29:8080/props | python3 -c 'import sys,json; p=json.load(sys.stdin); print("ctx:", p["default_generation_settings"]["n_ctx"]); print("model:", p["model_path"])'
ssh -i ~/.ssh/id_ed25519_rtx5090 "brentlichtenberg@gmail.com@192.168.1.29" "nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader"
```

If context came back lower than you expected:
- `--fit-ctx` is a floor, not a target — llama.cpp fits as much as it can above that floor. If you want an exact ctx, pass `--ctx-size N` explicitly (but then `--fit` won't rescue you if it doesn't fit).
- KV quantization misconfigured: if you dropped `--flash-attn on` or the build doesn't have `GGML_CUDA_FA_ALL_QUANTS=ON`, the q8_0 KV path falls back and context halves.
- Compute buffer larger than expected: `ubatch` too high for a smaller model; drop to 1024.

If VRAM usage is way higher than the file size + expected KV:
- **`--no-mmap` is off**. With GPU-only inference you want it *on* (i.e., flag present), so weights don't get double-loaded (mmap-ed in RAM *and* copied to VRAM). Check the launch script.
