---
name: local-llm
description: Open-weight LLM landscape knowledge for Ben's RTX 5090 — what models are worth running, how to discover new ones, and what the quant labels on Hugging Face actually mean. Use this skill whenever the user asks about local models, GGUF quantization, or the open-weight ecosystem, including questions like "what's the difference between Q6_K and UD-Q6_K_XL", "what does IQ4_XS mean", "Q4_0 vs IQ4_XS", "what's the best local coding model right now", "is there anything new from Unsloth", "should I try the MoE", "what quant fits in 32 GiB", "is DeepSeek / Qwen / Llama / Gemma / Mistral any good", "what's trending on Hugging Face", "can I run a 70B on my 5090", or any "which model should I run" / "which quant should I pick" question. Also use when the user mentions quant terminology (Q_K, IQ, UD-, _XL, MXFP4, imatrix), leaderboards (Aider, SWE-bench, LiveBench, LMSys Arena, HF Open LLM), or Hugging Face orgs (unsloth, bartowski). Knowledge cutoff is a real problem here — the model landscape changes weekly, so fetch current state from HF and leaderboards rather than answering from training data. Companion to `llama-cpp-rtx5090` (which owns the operational server setup); this skill owns the knowledge of what to run on it.
---

# local-llm

Open-weight LLM knowledge — what models exist, what the quant labels mean, what to pick for Ben's 32 GiB RTX 5090, and how to stay current in an ecosystem that ships new state-of-the-art every few weeks.

## Scope

**This skill owns:**
- Quant terminology (what `Q4_K_M`, `IQ4_XS`, `UD-Q6_K_XL`, `MXFP4`, etc. actually mean).
- VRAM math (what fits on a 5090 at what context length).
- Model comparisons (which open-weight model is currently best at coding / chat / long-context / vision).
- Discovery — how to find new models before they hit training data.
- Benchmark interpretation (which leaderboards to trust for what, and how to spot contamination).

**Defers to `llama-cpp-rtx5090`:**
- How to actually *run* a model on the 5090 (SSH, Scheduled Task, build flags, firewall, launch scripts). That skill is the operational half; this one is the knowledge half.

**Defers to `claude-local-model`:**
- Routing Claude Code to a local server. That skill handles the LiteLLM proxy and settings.json.

## Rule #0 — always prefer thinking mode

**Default to thinking mode for every llama-server call against a
thinking-capable model (Qwen3.5/3.6, DeepSeek-R1, etc.). Never
silently switch to instruct mode.**

Why this is the default, not a per-task decision:

- **Quality wins are real.** Instruct mode on Qwen3.6-27B in v6
  produced rhythm-template residue ("Action; visual result"
  templates that ignored the rhythm plan) that thinking mode
  broke out of. Even on bounded tasks (60-100 token blurbs,
  single-integer ratings, 200-word arcs), thinking improves
  consistency and reduces template residue.
- **The "speed win" of instruct is mostly a mirage.** Yes,
  visible decode is faster; but for any non-trivial task the
  quality gap forces a retry, eating the speed gain. The
  pattern over multiple Board Control bakes: instruct produced
  output we had to throw away or hand-edit; thinking produced
  output we shipped.
- **Silent mode-switches are a bug, not a feature.** The risk
  is configuring `enable_thinking: False` for a "small fast"
  task and forgetting it's there as the codebase evolves. Every
  llama-server caller in this codebase should have an explicit
  `"chat_template_kwargs": {"enable_thinking": True}` line —
  the explicitness is the defense against drift.

How to wire it correctly:

```python
body = {
    "model": MODEL_ALIAS,
    "messages": [...],
    "max_tokens": 12000,             # ≥ 8000 even for short visible
                                     # output — thinking eats budget
    "temperature": 1.0,              # general thinking preset
    "top_p": 0.95,
    "top_k": 20,
    "min_p": 0.0,
    "chat_template_kwargs": {"enable_thinking": True},
}
```

Sampler preset depends on the task:
- **Creative prose / open-ended writing** → `temp=1.0` (general thinking)
- **Structured output / consistent ratings / tool-call JSON** → `temp=0.6` (precise-coding thinking)
- **Per-checkpoint adjustments** (e.g. Qwen3.6-35B-A3B adds
  `presence_penalty=1.5`; Gemma 4 uses `top_k=64`) — fetch the
  current Unsloth recommendation per checkpoint.

`max_tokens` budgets must cover **both `<think>` and visible
output**:
- Single-integer rating: ≥ 4000 (thinking can run 2-3k)
- Bounded prose (60-200 tokens visible): ≥ 8000-12000
- Long-form prose (~500-1000 visible): ≥ 16000-32000
- Vision longform: ≥ 32000

Under-budgeting fails silently with empty visible output —
thinking eats the entire budget before the model emits the first
visible token. **A 200-token max with thinking on is broken; the
model produces nothing and the bake counts a zero-length row.**

Exceptions where instruct mode is actually right:
- Sub-1B utility models (Qwen3.5-0.8B for token classification,
  filename generation, etc.) — these don't have thinking.
- Cases where the user explicitly wants instruct mode for a
  reason (e.g. comparing the two modes head-to-head).

These are exceptions; they should be called out at the call site
with a comment explaining why. The default everywhere else is
thinking on.

## Rule #1 — don't answer from training data when freshness matters

Model knowledge decays fast. A new SoTA open-weight model ships every 2–4 weeks; quants are re-published weekly. Your training cutoff is always behind the truth.

**Always fetch, never guess, for questions like:**
- "What's the best [coding/chat/long-context/vision] model right now?"
- "Is there anything new from [Qwen/DeepSeek/Meta/Mistral/Gemma/Kimi/MiniMax]?"
- "What did Unsloth release recently?"
- "Is model X any good?" (where X was released after early 2026)
- "What's on the leaderboard for [Aider/SWE-bench/LiveBench] this month?"

Use `WebFetch` on the canonical URLs below. Then answer with date-stamped results.

**It's fine to answer from memory when the question is timeless:**
- "What does UD-Q6_K_XL mean?" → from `references/quant_taxonomy.md`.
- "How much VRAM does a 70B dense Q4 take?" → from `references/rtx5090_fit.md`.
- "Why does llama.cpp need CUDA 12.8 on Blackwell?" → from `references/rtx5090_fit.md`.

The line: **concept questions = baked knowledge; state-of-the-world questions = live fetch.**

**Capability questions count as state-of-the-world questions.**
"Does model X support vision / video / tool use / 256k context /
function calling?" looks like a concept question but isn't —
capability sets shift between point releases of the same model
family (Qwen3.5 vs 3.6, Llama 3.1 vs 3.3, etc.) and your training
data is frozen weeks before the model shipped. **If you find
yourself about to say "model X is text-only" or "model X doesn't
support Y" without having fetched, stop and fetch first.** This
skill exists specifically because that mistake is the most common
failure mode and it's expensive (you misdirect the user to an
unnecessary model swap).

## Canonical sources to fetch

Paste these into `WebFetch` as needed. Full rationale for each in `references/leaderboards.md`.

| Source | Use for |
|---|---|
| https://huggingface.co/unsloth | **Primary GGUF source.** Recent quants from Unsloth (UD-dynamic, imatrix-ready). Sort by "Recently Updated." |
| https://huggingface.co/bartowski | Secondary quanter — often has I-quant variants Unsloth doesn't. |
| https://huggingface.co/models?pipeline_tag=text-generation&library=gguf&sort=trending | Trending GGUFs. Good early-warning for new releases. |
| https://aider.chat/docs/leaderboards/ | **Best benchmark for picking a local coding model.** |
| https://www.swebench.com/ | SWE-bench Verified — real GitHub issues. |
| https://tbench.ai/ | Terminal-Bench — agentic command-line ability. |
| https://livebench.ai/ | Contamination-resistant general reasoning. |
| https://lmarena.ai/leaderboard | Human preference Elo — best for chat quality. |
| https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard | HF Open LLM v2 — broad academic benchmarks. |
| https://www.reddit.com/r/LocalLLaMA/top/?t=week | Community firsthand reports; read the top comments. |

## The three questions you'll answer most often

### 1. "What does quant X mean?" / "X vs Y?"

Look up the terms in `references/quant_taxonomy.md` — it has the full taxonomy (legacy Q, K-quants, I-quants, Unsloth Dynamic, MXFP4, BF16) and a head-to-head section for the common comparisons (Q6_K vs UD-Q6_K_XL, IQ4_XS vs Q4_0, etc.).

Structure your answer:
- What each label encodes (bit width, scheme, size).
- Which is bigger / smaller, by roughly how much.
- Which is higher quality, and by how much (ballpark perplexity or benchmark delta).
- Speed: usually identical on GPU; flag if that's not the case.
- Which to pick in context.

### 2. "What model should I run on my 5090?"

Gather constraints first — **don't immediately recommend from memory.** Ask yourself / the user:
- Task: agentic coding? chat? math? long-context? vision?
- Context length needed: 32k? 64k? 100k+?
- Dense vs MoE preference: MoE is usually faster per-token at larger sizes.

Then:
1. Fetch the relevant leaderboard (Aider for coding, LMSys for chat, LiveBench for reasoning, Open VLM for vision).
2. Filter to **open-weight** and size-appropriate for the 5090 (generally ≤ 40B total params — see `references/rtx5090_fit.md` for why 70B dense is a trap).
3. Cross-check against Unsloth's recent uploads: is there a GGUF? If not, check bartowski or quantize yourself.
4. Recommend a specific **model + quant + expected context**, not just a model name.

Current-ish default (as of April 2026 — **verify before stating**): Qwen3.6-35B-A3B @ UD-Q4_K_XL for coding, Qwen3.6-27B @ UD-Q6_K_XL for general use. Fetch fresh before recommending if it's been more than a couple weeks since this skill was updated.

### Qwen3.6 series — capabilities to remember

Released April 22, 2026 (27B dense) and April 16, 2026 (35B-A3B MoE).
Fast-moving capability set; known mistakes to avoid:

- **Both 27B and 35B-A3B are NATIVELY MULTIMODAL** — text + image
  + video. The same checkpoints that do agentic coding also do
  vision; you do not need a separate VL model. The 27B model card
  literally lists model type as "Causal Language Model with Vision
  Encoder."
- **Vision in llama.cpp requires a separate `mmproj` file**
  alongside the main GGUF. Unsloth ships it in the same repo
  (`mmproj-F16.gguf` or similar). Without `--mmproj`, llama-server
  loads text-only. **A common failure mode is assuming the model
  is text-only because the README leads with coding benchmarks.**
- **Hybrid attention** (gated delta networks). Native context is
  **262k tokens** for both sizes. Don't accept stale "128k" claims.
- **Thinking mode** is shared with non-thinking on the same
  weights; toggled by chat template kwargs. Sampler differs:
  general thinking is `temp=1.0, top_p=0.95, top_k=20, min_p=0.0`;
  precise-coding thinking is `temp=0.6` (rest same). Picking the
  wrong preset for the task silently degrades output (mode-collapse
  on creative tasks at temp=0.6).
- **vLLM lets you skip the vision encoder** with
  `--language-model-only`. llama.cpp loads vision iff `--mmproj` is
  passed.

Sample llama-server launch with vision (Unsloth docs):

```bash
./llama-server \
    --model Qwen3.6-27B-UD-Q6_K_XL.gguf \
    --mmproj mmproj-F16.gguf \
    --ctx-size 131072 \
    -ngl 99
```

If the user's task could plausibly use vision (board renderings,
charts, screenshots, document understanding) and they're already
running Qwen3.6, **default to suggesting they enable vision rather
than switching models.** Switching costs are zero — same weights,
extra ~1–2 GB for the projector.

### Small Qwen variants (for fine-tuning, on-device, or low-VRAM use)

The Qwen series ships dense small variants in the **Qwen3.5** family
(not 3.6 — the .6 line is large-only at 27B+). All available in
transformers/safetensors format on Unsloth, suitable for LoRA
fine-tuning:

- `unsloth/Qwen3.5-0.8B` — 0.8B, instruct (also `-Base`)
- `unsloth/Qwen3.5-2B` — 2B, instruct (also `-Base`)
- `unsloth/Qwen3.5-4B` — 4B, instruct (also `-Base`)

Pick **Qwen3.5-2B** as the default small student when distilling from
a Qwen3.6 27B / 35B-A3B teacher — same family, recent generation,
~4.6 GB safetensors. The older Qwen3-1.7B is from a previous
generation; don't reach for it unless you have a specific reason.

Note: Qwen3.5 small models inherit the multimodal processor (image +
video preprocessing configs in the repo even on 2B), so under Unsloth
you must call the tokenizer with `tokenizer(text=text, ...)` as a
keyword arg — the same fix Gemma 4 needs.

### 3. "What's new?"

Pattern:
1. Fetch `huggingface.co/unsloth` (recently updated). Flag any model you don't recognize.
2. Fetch `huggingface.co/models?sort=trending` — scope to GGUF via query params if needed.
3. Fetch `r/LocalLLaMA` top of week — helps separate "hype" from "actual capability."
4. For each candidate: fetch the model's HF page, read the README / model card for benchmarks, and cross-check against LiveBench / Aider if it's been there long enough.
5. Report back with: model name, size, release date, claimed capability, whether there's a GGUF available, whether it fits on a 5090, one-line recommendation.

## Glossary of terms that trip people up

- **Base vs Instruct vs Chat**: base is pretrained only (raw predict-next-token); instruct/chat is fine-tuned to follow instructions. For agentic use, always pick instruct/chat.
- **Dense vs MoE**: dense = all parameters active on every token; MoE = routed to a subset per token. MoE has more total params (bigger file) but faster decode (fewer params touched per token).
- **Active params** (MoE only): the subset of weights actually used per token. E.g. `35B-A3B` = 35B total, 3B active. Decode speed scales with active, not total.
- **Context length / ctx / n_ctx**: how many tokens the model can hold in attention. Training-time context (`n_ctx_train`) vs runtime context (what you configure) can differ — most models degrade past their training context.
- **imatrix / importance matrix**: calibration data used by I-quants and some K-quants to decide which weights matter most. Reputable quant repos always include it.
- **KV cache**: per-token memory of previous keys/values. Dominates VRAM at long contexts. Can be quantized (q8_0) to halve the cost.
- **Flash attention**: a fused, memory-efficient attention kernel. Required for quantized KV cache. Always on for the 5090.
- **Prefill vs decode**: prefill = processing the prompt in parallel; decode = generating tokens one at a time. Prefill is bandwidth-bound then compute-bound; decode is memory-bound.
- **Reasoning / thinking mode**: some recent models emit explicit `<think>...</think>` blocks before the answer. Enabled/disabled via chat template kwargs or sampler presets. Helps on hard reasoning, costs tokens.

## References

Three deep-dive references. Load the relevant one when a question goes past what's in SKILL.md.

- `references/quant_taxonomy.md` — full breakdown of every GGUF quant format, size math, and head-to-head comparisons. Load when the user asks about quant labels or tradeoffs.
- `references/leaderboards.md` — which benchmarks measure what, their refresh cadences, contamination caveats, and URLs to fetch. Load when answering "what's best" or "is X actually good."
- `references/rtx5090_fit.md` — VRAM math, per-model-size sweet spots, Blackwell-specific kernel/perf notes. Load when sizing a model for the 5090.

## When to defer

- **Running a model on the 5090** (SSH, build, scheduled tasks, launch flags): **`llama-cpp-rtx5090`**.
- **Wiring a local model into Claude Code** (proxy, routing, settings.json): **`claude-local-model`**.
- **Running a model on iOS/macOS** (llama.cpp XCFrameworks, mtmd vision): **`llama-cpp-ios`** / **`mtmd-vision`**.
- **Fine-tuning / training a model**: **`train-on-rtx5090`** for the remote GPU, **`yolo-finetune`** for the YOLO-specific workflow.
- **General non-local LLM questions** (using the Claude API, prompt engineering outside this stack): no skill; answer directly.

## Self-maintenance

This skill will drift. The leaderboard-URL set is stable but the *answers to "what's best right now"* aren't. If you notice that something here is out of date — e.g., a leaderboard changed its URL, a recommended model was deprecated — update the reference files rather than letting stale guidance persist. Suggest updates to the user proactively when you spot them.
