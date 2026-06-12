# Trusted leaderboards and discovery sources

A menu of places to consult when the user asks "what's the best model right now for X" or "is there anything new worth trying." **Always fetch one of these live** — ranking a model from memory gets you an answer from your training cutoff, which is always wrong within a few weeks.

## Contents

1. Quick matrix: "what to check for what question"
2. Leaderboards — detailed entries
3. Model discovery sources (non-leaderboard)
4. Reading a leaderboard result critically
5. Contamination and gaming: how to sanity-check a suspicious result

## 1. What to check for what question

| If the user asks… | Go here first |
|---|---|
| "best model for coding right now" | Aider + SWE-bench Verified + Terminal-Bench |
| "best overall chat/instruction model" | LMSys Chatbot Arena, LiveBench |
| "best model that fits in X GiB" | HF Open LLM Leaderboard v2, filter by size + quant |
| "what did Unsloth publish recently" | huggingface.co/unsloth (sort by "Recently Updated") |
| "what's trending on HF this week" | huggingface.co/models?sort=trending |
| "is model X actually good or hype" | LiveBench (contamination-resistant) + r/LocalLLaMA threads |
| "best open-weight model beating GPT-5 / Claude at X" | LMSys Arena (head-to-head), LiveBench |
| "multimodal / vision-language model for local" | Open VLM Leaderboard, HF trending (filter multimodal) |
| "specific quant of a specific model" | bartowski or unsloth GGUF pages, comments section |

## 2. Leaderboards — detailed entries

### LMSys Chatbot Arena — https://lmarena.ai/leaderboard

Human-preference head-to-head Elo. Users send the same prompt to two anonymized models and vote for the better reply.

- **What it measures well**: subjective chat quality, instruction-following, writing. The signal is "which model do humans like more on average."
- **What it measures poorly**: capability on tasks humans can't evaluate casually (formal math, code correctness without running it, domain-specific reasoning). Also heavily influenced by *style* — verbose, confident answers outrank terse correct ones.
- **Refresh**: continuous; new models show up within days.
- **Use it for**: ranking conversational models, spotting a genuinely new SoTA.
- **Don't use it alone for**: picking a coding model.

### LiveBench — https://livebench.ai/

Monthly-refreshed held-out benchmark from Yann LeCun's group (NYU). New test items are generated every month from recent academic/public sources that couldn't have been in any training run yet.

- **What it measures well**: *un-contaminated* reasoning, math, code, data-analysis. The only mainstream benchmark with a strong contamination guarantee.
- **Refresh**: monthly problem rotation; top models re-evaluated with each rotation.
- **Use it for**: "is this new model *actually* better, or did it memorize the training set." When a model tops LiveBench *and* stays on top across rotations, that's real capability.
- **Caveat**: tests reasoning, not tool-use or agentic behavior.

### Aider LLM Leaderboard — https://aider.chat/docs/leaderboards/

Measures real code-editing: can the model edit an existing codebase correctly, applying unified diffs or whole-file replacements to pass a real test suite.

- **What it measures well**: practical coding agent performance — exactly the task Claude Code, Cursor, Aider, and similar tools ask of a model. Distinguishes "can write code from scratch" from "can correctly modify existing code," and the latter is much harder.
- **Refresh**: whenever Aider's author adds a new model; usually within 2–3 weeks of release.
- **Use it for**: picking a local model to serve in Claude Code / Cursor / similar. **This is the single most relevant benchmark for agentic coding.**
- **Caveat**: only covers models paul-gauthier has tested; some open-weight models with limited compute access lag on this list.

### SWE-bench Verified — https://www.swebench.com/

2,294 real GitHub issues from 12 popular Python repos, each paired with the test suite that validates the fix. "Verified" subset = 500 hand-filtered to be unambiguous.

- **What it measures well**: end-to-end agentic debugging — read a codebase, understand an issue, make a patch that passes tests. The gold standard for "can this model do real maintenance engineering."
- **Refresh**: static benchmark; new models scored as labs / community evaluate them.
- **Use it for**: headline-grabbing agentic coding comparisons. Top scores (>70% on Verified as of April 2026) come from frontier closed models + the strongest open-weight coders.
- **Caveat**: Python-only, lopsided toward certain repos' idioms. A model can score 60% here and still be a terrible generalist coder.

### SWE-bench Pro — https://www.swebench.com/pro/

Extension of SWE-bench to more repos and harder issues, released 2026. Fewer models have been evaluated; useful as a "does this really hold up" check after a model aces Verified.

### Terminal-Bench — https://tbench.ai/

Agentic command-line benchmark: can the model achieve a goal by running shell commands, reading outputs, and iterating. Version 2.0 released mid-2026.

- **What it measures well**: tool-use reliability over many turns. Weaknesses in long-horizon agent behavior (getting lost, forgetting the goal, hallucinating file contents) are visible here in a way they're not on single-shot benchmarks.
- **Use it for**: picking a model for Claude Code / any agent that runs commands.

### HuggingFace Open LLM Leaderboard v2 — https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard

Aggregates MMLU-Pro, GPQA, IFEval, MATH, BBH, MuSR. Open-weight models only.

- **What it measures well**: broad academic-benchmark average. Good sanity check, especially for smaller / less-hyped models that don't get covered by Aider or Arena yet.
- **Refresh**: every new submission re-scored; users submit models.
- **Caveat**: uses standard benchmarks that are **partially contaminated** at this point — treat raw scores skeptically and cross-check with LiveBench.

### Open VLM Leaderboard — https://huggingface.co/spaces/opencompass/open_vlm_leaderboard

OpenCompass-run multimodal leaderboard (image-in, text-out).

- **Use it for**: picking a vision-language model. Covers Qwen-VL, InternVL, LLaVA-family, etc.
- **Caveat**: doesn't yet include OCR-heavy or chart-reading benchmarks well; for document understanding check MMMU + DocVQA separately.

### Artificial Analysis — https://artificialanalysis.ai/

Aggregated model comparisons with price, speed, and quality side-by-side. Good for "is the local-model quality gap worth the cost savings" business-case questions.

- **Use it for**: quick snapshot of a model's position relative to GPT-5, Claude, Gemini on price-per-token and tokens-per-second. Pulls from multiple source benchmarks.

### Scale SEAL — https://scale.com/leaderboard

Private held-out benchmarks on reasoning, coding, multilingual, adversarial robustness. Less susceptible to contamination than public benchmarks.

- **Use it for**: when you suspect a model is overfit to public benchmarks and want a private-eval sanity check.

## 3. Model discovery sources (non-leaderboard)

### huggingface.co/unsloth

Daniel Han's org ships GGUF quants of essentially every interesting open-weight release within days, including UD-dynamic quants no one else has.

- **What to look for**: "Recently Updated" on the Models tab.
- **Why this is the primary GGUF source**: Unsloth maintains imatrix files, publishes multiple quants per model, and documents their calibration methodology. Their repo quality is consistently higher than random ad-hoc quanters.
- **Typical repo pattern**: `huggingface.co/unsloth/<model>-GGUF` with a README explaining the specific quant strategy.

### huggingface.co/bartowski

Bartowski is the other major individual quanter. Often publishes the same models as Unsloth but with a different quant lineup (more I-quant variants, imatrix files for all).

- **When to check**: if Unsloth hasn't quantized a specific model yet, bartowski probably has. Also useful when you want an `IQ` variant Unsloth didn't publish.

### huggingface.co/models?sort=trending

HF's trending feed, sorted by downloads + activity in the last 24h.

- **Why it's useful**: catches breakout releases before leaderboards update. When a lab drops a genuinely interesting model, HF trending picks it up within hours.
- **Filter tricks**: `?pipeline_tag=text-generation&library=gguf&sort=trending` to scope to GGUFs. Add `&search=unsloth` to scope to Unsloth's quants specifically.

### r/LocalLLaMA — https://www.reddit.com/r/LocalLLaMA/

The community watercooler. Benchmarks, reviews, benchmarks-of-benchmarks, GGUF-availability threads, practical deployment notes.

- **What's useful**: "X vs Y on RTX 5090" type firsthand benchmark reports, discussions of new model quirks that don't show up in leaderboards.
- **What's noise**: hype-driven top posts, cherry-picked one-off results. Sort by "Top (past week)" and read the top-voted *comments*, not just the headlines.

### lmstudio.ai catalog — https://lmstudio.ai/models

LM Studio maintains a curated model catalog with size / recommended quant / compatibility notes. Useful for a quick "what's currently considered good" without wading through benchmarks.

## 4. Reading a leaderboard result critically

Before recommending a model based on a leaderboard score:

1. **Check the release date.** A model released within the last 2 weeks on a leaderboard that updates within days may still be riding the hype curve. Cross-check against a second source.
2. **Check the size / quant.** A 70B model topping a 30B bucket isn't a meaningful comparison. Filter to your VRAM range first.
3. **Check whether the leaderboard's evaluation allows tool use, chain-of-thought, or specific prompt scaffolding.** Scores can vary 10–20% depending on these settings — make sure you can reproduce the config locally.
4. **Don't average across benchmarks that test different things.** An HF Open LLM aggregate score is smoothed across 6 things; look at the individual bench breakdowns for the dimensions you actually care about.

## 5. Contamination and gaming

Public benchmarks leak into training sets. Signs a model is contaminated rather than capable:

- **Surprise huge jump** on a specific benchmark without commensurate gain elsewhere.
- **Model is fine-tuned from a base with a much lower score** (possible, but warrants LiveBench / private-eval cross-check).
- **Benchmark is listed in the model's training-data documentation**, or derived from a publicly-crawlable source.
- **Performance on the benchmark's public test set is far above held-out rotations** (LiveBench exposes this directly — monthly rotation scores that drop sharply after a new rotation = contamination).

When suspicious, default to LiveBench (which rotates) or Scale SEAL (which is private) for the sanity check. Or just test on your own workload — the only benchmark that matters is the one that reflects what you actually use the model for.

## Canonical set of URLs

Keep these close; these are the fetch targets when the user asks for current state:

- https://lmarena.ai/leaderboard
- https://livebench.ai/
- https://aider.chat/docs/leaderboards/
- https://www.swebench.com/
- https://tbench.ai/
- https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard
- https://huggingface.co/spaces/opencompass/open_vlm_leaderboard
- https://huggingface.co/unsloth
- https://huggingface.co/bartowski
- https://huggingface.co/models?pipeline_tag=text-generation&library=gguf&sort=trending
- https://www.reddit.com/r/LocalLLaMA/top/?t=week
- https://artificialanalysis.ai/
