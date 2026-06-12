# GGUF quantization taxonomy

Complete reference for the GGUF quant formats you'll see on Hugging Face — what each label means, how it's actually encoded, how it trades off against the others. Grouped by **family**, because the differences within a family are small and well-understood, while the differences *between* families (legacy vs K vs I vs Unsloth Dynamic) are where real quality and speed gaps live.

## Contents

1. Nomenclature cheat sheet
2. Legacy quants (Q4_0, Q4_1, Q5_0, Q5_1, Q8_0)
3. K-quants (Q2_K → Q8_K)
4. I-quants (IQ1_S → IQ4_XS)
5. Unsloth Dynamic quants (UD-*)
6. MXFP4 and FP-family (for MoE and Blackwell)
7. Full-precision floats (BF16, FP16, FP32)
8. Head-to-head comparisons (answers for "Q6_K vs UD-Q6_K_XL", "IQ4_XS vs Q4_0", etc.)
9. Quick decision tree for picking a quant on a 32 GiB GPU

## 1. Nomenclature cheat sheet

Most quant labels are structured: `[prefix_]Q<bits>_<family>[_<size>]`.

| Token | Meaning |
|---|---|
| `Q` | "quantized" weights (packed below FP16) |
| `<bits>` | target bits per weight on the *majority* of tensors — 2, 3, 4, 5, 6, 8 |
| `_0` / `_1` | legacy variants. `_0` = symmetric (scale only). `_1` = asymmetric (scale + zero-point, ~5% bigger, marginally higher quality). |
| `_K` | K-quant family (k-means-style mixed-precision, llama.cpp's modern default) |
| `IQ` | I-quant family (importance-matrix weighted) |
| `_S` / `_M` / `_L` | Small / Medium / Large variant *within* a bit level — denser layers get higher-bit blocks |
| `_XL` | eXtra Large — Unsloth-specific, even more bits on critical layers |
| `UD-` | Unsloth Dynamic prefix — uses a calibration dataset to decide per-layer bit allocation |
| `IQ<n>_XXS/XS/S` | I-quant size variants within a bit level; XXS < XS < S |
| `MXFP4` | Microscaling FP4 (OCP standard) — 4-bit floats with per-block scale |
| `_MOE` suffix | quant was calibrated/allocated with MoE-specific routing in mind |

Size intuition on a 30B dense model (roughly scales linearly for other sizes):

```
BF16       ≈ 60 GiB
Q8_0       ≈ 30 GiB
Q6_K       ≈ 25 GiB
Q5_K_M     ≈ 21 GiB
Q4_K_M     ≈ 18 GiB
IQ4_XS     ≈ 17 GiB
Q3_K_M     ≈ 15 GiB
IQ3_XS     ≈ 13 GiB
Q2_K       ≈ 11 GiB
IQ2_XS     ≈ 9  GiB
```

## 2. Legacy quants: Q4_0, Q4_1, Q5_0, Q5_1, Q8_0

The original llama.cpp quants. Simple per-block scale (and optional zero-point). Uniform bit width across every tensor.

- **Q4_0** — 32 weights share one `fp16` scale. 4.5 bpw effective (bits per weight). Worst of the commonly used formats; ~10% higher perplexity than Q4_K_M at the same size.
- **Q4_1** — adds a per-block `fp16` zero-point. 5.0 bpw. Slightly better quality, but Q4_K_M beats it at less size.
- **Q5_0 / Q5_1** — same idea at 5 bits. Obsolete, use Q5_K_M instead.
- **Q8_0** — 8-bit, symmetric, scale-only. 8.5 bpw. Very close to BF16 quality (<1% perplexity loss). Good reference point for "lossless enough." Commonly used for **KV cache** quantization (`--cache-type-k q8_0 --cache-type-v q8_0`) where dequant cost matters more than weight compression ratio.

**When to use legacy quants today**: only Q8_0, and primarily for the **KV cache**. For weights, K-quants or I-quants always win.

## 3. K-quants: Q2_K → Q8_K

Introduced in mid-2023. Llama.cpp's default family. "K" = k-means-style bit allocation across a super-block: some tensors within a block get more bits than others, based on importance. Size variants (`_S`/`_M`/`_L`) differ in how generously the "important" tensors are treated.

| Label | Avg bpw | Used for |
|---|---|---|
| Q2_K | 3.35 | extreme compression — noticeable quality drop |
| Q3_K_S | 3.50 | small 3-bit |
| Q3_K_M | 3.90 | balanced 3-bit |
| Q3_K_L | 4.25 | larger 3-bit, most layers ≥ 4 bits |
| Q4_K_S | 4.50 | tight 4-bit |
| Q4_K_M | 4.85 | **the common default for dense models** |
| Q5_K_S | 5.50 | |
| Q5_K_M | 5.70 | high quality, modest size |
| Q6_K | 6.57 | near-lossless for dense; ~0.5–1% perplexity vs BF16 |
| Q8_K | 8.50 | same ballpark as Q8_0; rarely seen standalone, used internally |

**K-quant structure** (simplified): each tensor is split into super-blocks of 256 weights. Each super-block has sub-blocks (32 weights each). The K-quant applies *different* bit widths to different sub-blocks based on a per-super-block importance heuristic, and stores the scales compactly. Net effect: quality-at-size roughly 10–20% better than legacy at the same bits.

**Gotcha — sizes within K:** `_S` / `_M` / `_L` within one bit level **do not overlap** the next bit level. E.g. `Q4_K_L` ≠ `Q5_K_S` ≠ `Q5_K_M`. Each is its own allocation strategy.

## 4. I-quants: IQ1_S, IQ2_XXS, IQ3_XS, IQ4_XS, IQ4_NL

Introduced late 2023 / early 2024. "I" = importance-matrix-weighted. Instead of allocating bits based on in-block statistics alone, I-quants require a **calibration pass** over a small text corpus to measure *which weights actually move the output most*, and allocate bits preferentially to those.

The practical result: at the same file size, I-quants are roughly **one-quality-tier above** K-quants. An `IQ4_XS` (~4.25 bpw) is comparable in quality to a `Q4_K_M` (~4.85 bpw) despite being smaller.

Common variants:

| Label | Avg bpw | Note |
|---|---|---|
| IQ1_S / IQ1_M | ~1.6 | extreme; quality varies wildly model-to-model |
| IQ2_XXS | 2.15 | |
| IQ2_XS | 2.30 | |
| IQ2_S / IQ2_M | 2.50 / 2.70 | |
| IQ3_XXS | 3.10 | |
| IQ3_XS | 3.30 | good 3-bit |
| IQ3_S | 3.50 | |
| IQ3_M | 3.70 | |
| IQ4_XS | 4.25 | **very popular** — smaller than Q4_K_M with similar quality |
| IQ4_NL | 4.50 | "Non-Linear" variant, slightly denser than IQ4_XS |

**Drawbacks of I-quants**:
1. **Build dependency**: the quantizer needs the calibration data (`imatrix.dat`). If a repo uploads IQ quants without the imatrix file, you can't re-quant from those weights. Reputable repos (Unsloth, bartowski, TheBloke-successors) always include it.
2. **CPU dequant is slower** than K-quants — I-quant kernels have more bookkeeping. On a pure-GPU run (which is our case on the 5090), this is irrelevant; I-quants run on CUDA at the same speed as K-quants.
3. **No CPU-offload-friendly format below 4 bits**: if you're offloading MoE experts to CPU RAM, stay in K-quants there.

**Rule of thumb**: on a GPU-only setup, prefer `IQ4_XS` over `Q4_K_M`, and `IQ3_M` over `Q3_K_M`, when both are available.

## 5. Unsloth Dynamic (UD-) quants

Unsloth (huggingface.co/unsloth) publishes their own re-quantizations with two innovations over the standard K-quants:

1. **Per-layer bit allocation**: instead of treating all layers uniformly, they profile the model on a calibration set and give more bits to attention-output and gating layers (which drive quality) at the expense of things like QKV projections (which tolerate lower bits). The result is similar in spirit to I-quants but done at the layer granularity.
2. **`_XL` tier**: each Unsloth quant comes in multiple sizes — the `_XL` variant spends ~10% more disk for meaningful quality gains, especially on long contexts and tool-call fidelity.

Common UD variants:

| Label | Rough size vs plain K | Use when |
|---|---|---|
| UD-Q2_K_XL | ~1.1× Q2_K | you need sub-3-bit for a very large model |
| UD-Q3_K_XL | ~1.1× Q3_K_M | |
| UD-Q4_K_XL | ~1.15× Q4_K_M | **default MoE choice** — quality ≈ Q5_K_M at less size |
| UD-Q5_K_XL | ~1.1× Q5_K_M | |
| UD-Q6_K_XL | ~1.1× Q6_K | **near-lossless for dense**, only ~4% bigger than plain Q6_K |
| UD-Q8_K_XL | ~1.05× Q8_0 | BF16-indistinguishable for most purposes |

**Why `_XL` is usually the right Unsloth pick**: the extra ~10% of weight size buys quality that would otherwise require stepping up a full bit level. Worth it unless you're tight on VRAM.

**When UD beats I-quants**: for complex tool-calling and multi-turn agentic behavior, the per-layer bit allocation in UD tends to edge out I-quants — the layers that matter for instruction-following get treated correctly. For raw perplexity on text, they're roughly tied at the same size.

**Where Unsloth publishes**: `huggingface.co/unsloth/<model>-GGUF`. Prefix `UD-` quants live alongside standard ones; pick by filename.

## 6. MXFP4 and FP-family

### MXFP4 ("Microscaling FP4")

Open Compute Project standard 4-bit floating-point format. Each block of 32 weights shares a shared FP8 exponent, with individual FP4 mantissas. Not an integer quant — a true float format.

- **Why it's exciting**: at the same 4-bit size, FP4 handles weights with very large or very small magnitudes better than integer quants, because it has exponent range. Especially good for MoE models where per-expert weight distributions vary.
- **Blackwell hardware support**: RTX 5090 has native FP4 tensor cores. When llama.cpp dispatches MXFP4 kernels, it can hit the Tensor Core path and match K-quant speed; on older GPUs it runs in emulated mode and is 2–3× slower.
- **Where to find it**: `MXFP4_MOE` suffix on Unsloth MoE repos (`Qwen3.6-35B-A3B-GGUF` has one). Newer, less battle-tested than UD-Q4_K_XL — benchmark before trusting it for production.

### BF16 / FP16 / FP32

- **BF16** — "brain float 16." Same exponent range as FP32, but with reduced mantissa. 16 bpw. This is the native training format for most modern models; using BF16 GGUFs means zero quantization loss.
- **FP16** — older IEEE 754 half-precision. 16 bpw. Smaller exponent range than BF16, so occasional overflow on weights trained in BF16. Prefer BF16 when given the choice.
- **FP32** — full precision. 32 bpw. No one serves this at scale; used during training and as the reference.

**When to use BF16**: small (≤ 13B) models where the full-precision file fits in VRAM alongside a generous KV cache. On a 5090, a 13B BF16 model (~26 GiB) is viable with ~6 GiB KV budget (ctx ≈ 24k). For 27B+ you have to quantize.

## 7. Head-to-head: common comparisons

### Q6_K vs UD-Q6_K_XL

- **Size**: UD-Q6_K_XL is ~3–5% larger.
- **Quality**: UD wins by a small but real margin, especially on multi-turn / tool-calling benchmarks where the per-layer allocation pays off. On raw perplexity the gap is < 1%.
- **Speed**: identical — same dequant path, same kernels.
- **Verdict**: if you can spare the VRAM, take UD-Q6_K_XL. It's ~4% more disk/VRAM for strictly-better behavior.

### IQ4_XS vs Q4_0

- **Size**: IQ4_XS (~4.25 bpw) ≈ 6% smaller than Q4_0 (~4.5 bpw).
- **Quality**: IQ4_XS wins decisively — Q4_0 is a legacy uniform-bit quant with no importance weighting. Typical perplexity gap: Q4_0 is 8–12% worse.
- **Speed**: identical on GPU. On CPU, Q4_0 dequant is marginally faster (doesn't really matter).
- **Verdict**: no reason to pick Q4_0 over IQ4_XS in 2026. Q4_0 only persists because some very old tooling only supports the legacy formats.

### IQ4_XS vs Q4_K_M

- **Size**: IQ4_XS (~4.25 bpw) is ~12% smaller than Q4_K_M (~4.85 bpw).
- **Quality**: roughly tied on perplexity; Q4_K_M edges ahead on some tool-call benchmarks by a few percent.
- **Speed**: identical on GPU.
- **Verdict**: if VRAM-constrained, take IQ4_XS. If you have headroom, Q4_K_M is marginally safer on long agentic chains.

### UD-Q4_K_XL vs IQ4_XS (for MoE)

- **Size**: UD-Q4_K_XL (~4.6 bpw) is ~8% larger than IQ4_XS.
- **Quality**: UD wins on MoE by a meaningful margin. MoE models have wildly varying per-expert weight distributions, which the per-layer UD allocation handles; I-quants are calibrated on full activations and don't adapt as well.
- **Verdict**: for any MoE (Qwen3.6-35B-A3B, DeepSeek-V3 variants, etc.), UD-Q4_K_XL is the standard pick. Use IQ4_XS only if you genuinely can't spare the VRAM.

### MXFP4 vs UD-Q4_K_XL (on Blackwell)

- **Size**: MXFP4 (~4.25 bpw) slightly smaller.
- **Quality**: on MoE, trending roughly equal to UD-Q4_K_XL. On dense models, UD tends to win (MXFP4 was designed with MoE in mind).
- **Speed**: on Blackwell's FP4 tensor cores, MXFP4 can be 1.3–1.8× faster at prefill than K-quant; on decode the KV cache dominates and the gap shrinks.
- **Verdict**: worth benchmarking head-to-head on your specific model if you care about prefill speed. Still newer and less tooling-mature than UD — not a "trust by default" pick yet.

### Q8_0 KV cache vs F16 KV cache

Not a weight quant but the most impactful VRAM lever after weights. With `--cache-type-k q8_0 --cache-type-v q8_0` you roughly **halve** KV memory for < 1% quality loss on most models (flash-attention required). This is what turns "can I fit 32k ctx?" into "can I fit 96k ctx?" on a 5090.

## 8. Quick decision tree for the 5090

Given a new model with parameter count P, a rough process for picking a quant:

1. **Compute VRAM budget**: 32 GiB total, ~1 GiB driver/desktop overhead, target 64k ctx with q8_0 KV. KV ≈ `P × 0.1 GiB/B-params` for 64k ctx on typical models. So weights budget ≈ 31 – KV – 1.
2. **Convert budget to bpw**: `bpw = (weights_budget_GiB × 8) / P_in_billions`.
3. **Snap to a quant** whose avg bpw is ≤ that number. Prefer UD > I > K > legacy in that order.

Worked example (30B dense): 31 - 3 (KV) - 1 = 27 GiB weights → 7.2 bpw → Q6_K (6.57 bpw) or UD-Q6_K_XL (~6.9 bpw) fits with room to spare.

Worked example (70B dense): 31 - 7 (KV) - 1 = 23 GiB weights → 2.6 bpw → IQ2_M (~2.7 bpw) at best, with reduced context. For a 5090, **70B dense is not a great fit** — quality at IQ2 is poor. Better to use a 30B dense or a 35B-A3B MoE.

Worked example (35B-A3B MoE): active params matter for decode speed but *total* for VRAM. 31 - 3 (KV; active-params-scaled) - 1 = 27 GiB weights → 6.2 bpw for 35B-total → UD-Q6_K_XL fits → but the real sweet spot is UD-Q4_K_XL (~4.6 bpw, ~20 GiB) because MoE quality is almost as good at Q4 as dense is at Q6, *and* you get more context headroom.

## 9. Where label choices actually matter

- **For dense coding models (e.g. Qwen3.6-27B)**: UD-Q6_K_XL is the quality-per-GiB sweet spot. Q6_K if you need to squeeze.
- **For MoE coding models (e.g. Qwen3.6-35B-A3B)**: UD-Q4_K_XL. Going higher wastes VRAM that would go to context; going lower hurts tool-call reliability.
- **For KV cache**: q8_0 for both K and V, always, on the 5090. Required for long-context agentic work.
- **For very small models (≤ 8B)**: Q8_0 or BF16 — no reason to quantize further when the whole thing fits easily.

Don't chase trends into untested quant formats during a real working session. Benchmark MXFP4, IQ1_M, and other experimental formats on their own time.
