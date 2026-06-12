---
name: litert-lm-ios
description: "Google's LiteRT-LM framework for on-device LLM and multimodal inference on iOS, and Gemma 4 edge models (E2B, E4B). Use this skill when evaluating LiteRT-LM as an alternative to llama.cpp for on-device inference, when working with Gemma 4 models on iOS, or when comparing frameworks for mobile vision/multimodal AI. Also use when you see references to .litertlm model files, the LiteRTLM Swift package, Google AI Edge Gallery, or questions about Gemma vs Qwen for on-device vision tasks."
---

# LiteRT-LM for iOS

LiteRT-LM is Google's production-ready, open-source inference framework for running LLMs on edge devices. It's the successor to TensorFlow Lite for generative AI, released April 2026.

## Current iOS Status (April 2026)

**Swift SDK: In Development ("Coming Soon")**

This is the critical constraint for this project. As of April 2026:

| Platform | Status | API |
|----------|--------|-----|
| Android/Kotlin | Stable | Full SDK with GPU/NPU acceleration |
| Python | Stable | Full SDK |
| C++ | Stable | High-performance native |
| **Swift/iOS** | **In Development** | Pre-built SDK announced but not fully shipped |
| Web | Supported | WebGPU acceleration |

The README says "Swift: Native iOS & macOS (Coming Soon)". There's a known bug where the iOS Metal accelerator dylib in `litert_prebuilts.zip` is incorrectly packaged as macOS x86_64 instead of iOS arm64 (GitHub issue #6745). This means **GPU acceleration on iOS is currently broken** — you'd be limited to CPU-only inference.

### What This Means for WheatOrSoy

LiteRT-LM is not yet a viable production path for an iOS app that needs GPU-accelerated multimodal inference. The Android story is strong; the iOS story is incomplete. If building for iOS today, llama.cpp is the proven path. LiteRT-LM becomes interesting to revisit once the Swift SDK ships with working Metal support.

## Model Format

LiteRT-LM uses its own `.litertlm` model format, not GGUF. Models are distributed via HuggingFace:

```
litert-community/gemma-4-E2B-it-litert-lm
litert-community/gemma-4-E4B-it-litert-lm
```

This is a separate ecosystem from GGUF/llama.cpp. You can't use the same model files across both frameworks.

## Gemma 4 Edge Models

Gemma 4 is Google's latest open model family. The "E" (Edge) variants are designed for on-device deployment:

| Model | Effective Params | RAM (4-bit) | Multimodal | Notes |
|-------|-----------------|-------------|------------|-------|
| E2B | 2.3B | ~1.5 GB | Vision + Audio | Runs on Raspberry Pi 5 |
| E4B | 4B | ~2.5 GB | Vision + Audio | Better accuracy, needs more RAM |
| 4B | 4B | ~2.5 GB | Vision + Audio | Non-edge variant |
| 12B | 12B | ~7 GB | Vision + Audio | Desktop-class |

### Per-Layer Embeddings (PLE)

The "effective" parameter count comes from PLE — a technique where embedding layers are memory-mapped and loaded per-layer rather than all at once. This is why E2B can run in 1.5 GB despite having 2.3B effective parameters. This is a LiteRT-LM specific optimization; GGUF quantization takes a different approach.

### Vision Capabilities

Gemma 4 E2B supports:
- Object detection with bounding boxes
- Document/PDF parsing
- Screen and UI understanding
- OCR (multilingual)
- Handwriting recognition
- Chart comprehension
- "Pointing" (spatial grounding)

**Bounding box format**: `[y1, x1, y2, x2]` — note this is **y-first**, unlike Qwen which uses `[x, y, width, height]`. The model outputs JSON with labels and bounding box coordinates.

**Grounding quality**: Gemma 4 can do bounding box detection when prompted, but it was not purpose-built for spatial grounding the way Qwen-VL models were. Qwen has a dedicated grounding training objective; Gemma 4's grounding comes from general vision fine-tuning. For shelf-scanning with multiple overlapping products, Qwen's grounding is likely more reliable.

## Gemma 4 E2B via llama.cpp (Alternative Path)

Importantly, **Gemma 4 E2B works in llama.cpp too** — you don't need LiteRT-LM to use Gemma models. GGUF versions are available:

```
ggml-org/gemma-4-E2B-it-GGUF    (main + mmproj)
unsloth/gemma-4-E2B-it-GGUF     (quantized variants)
```

This means the framework choice (llama.cpp vs LiteRT-LM) and the model choice (Qwen3.5 vs Gemma 4) are **independent decisions**. You can run Gemma 4 in llama.cpp or Qwen3.5 in llama.cpp, using the same mtmd pipeline.

## Comparison: LiteRT-LM vs llama.cpp for iOS

### Framework Comparison

| Aspect | llama.cpp | LiteRT-LM |
|--------|-----------|-----------|
| iOS maturity | Production-ready | Swift SDK in development |
| GPU acceleration (iOS) | Metal works | Metal dylib broken (issue #6745) |
| Model format | GGUF (universal) | .litertlm (proprietary) |
| Multimodal API | mtmd (C API, stable) | Kotlin API stable; Swift TBD |
| Community | Very active, wide model support | Google-backed, narrower model set |
| Build complexity | CMake from source + XCFramework | Pre-built SDK (when shipped) |
| Quantization | Q2-Q8, many variants | 2-bit and 4-bit, PLE |
| Model ecosystem | Qwen, Gemma, Llama, Phi, etc. | Gemma, Llama, Phi-4, Qwen |

### Model Comparison for WheatOrSoy

| Aspect | Qwen3.5-2B (llama.cpp) | Gemma 4 E2B (llama.cpp) | Gemma 4 E2B (LiteRT-LM) |
|--------|----------------------|----------------------|------------------------|
| Download size | ~1.95 GB (Q4_K_M + mmproj) | ~1.5 GB (Q4_K_M + mmproj) | ~1.5 GB (.litertlm) |
| RAM at runtime | ~1.5 GB | ~1.5 GB | ~1.5 GB (with PLE) |
| iOS GPU | Yes (Metal) | Yes (Metal) | No (broken) |
| Bounding box grounding | Strong (trained objective) | Works (general vision) | N/A for iOS |
| OCR quality | 84.5 OCRBench | Good (no public OCRBench) | N/A for iOS |
| Bbox format | `[x, y, w, h]` normalized | `[y1, x1, y2, x2]` | N/A for iOS |
| Fine-tuning path | Unsloth Studio (0.8B target) | Unsloth + Keras | N/A |
| License | Apache 2.0 | Gemma license (permissive) | Gemma license |

### Recommendation for WheatOrSoy

**Ship with llama.cpp + Qwen3.5-2B** (current plan). Reasons:

1. **iOS maturity**: llama.cpp has working Metal acceleration on iOS today. LiteRT-LM doesn't.
2. **Grounding**: Qwen3.5 has purpose-built bounding box grounding. Gemma 4's grounding is general-purpose and less tested for multi-object shelf scanning.
3. **Fine-tuning path**: The plan to fine-tune Qwen3.5-0.8B via Unsloth for a domain-specific wheat/soy model is well-supported. A fine-tuned 0.8B specialist (738 MB) is the ideal production model.
4. **Gemma 4 E2B is a strong v2 candidate** — once you have the llama.cpp pipeline working, swapping in Gemma 4 E2B as an alternative model is trivial (same mtmd API, just different GGUF files). You could offer it as an in-app model choice alongside Qwen3.5.

### When to Revisit LiteRT-LM

- When the Swift SDK ships with working Metal acceleration
- When .litertlm models with PLE demonstrate better memory efficiency than GGUF Q4_K_M
- If Google adds dedicated grounding/detection APIs that outperform prompt-based bbox extraction

## API Surface (Kotlin — for Reference)

Since the Swift API isn't available yet, here's the Kotlin API pattern for reference. The Swift API will likely mirror this:

```kotlin
// Load model
val model = LlmModel.load(
    context,
    modelPath = "gemma-4-E2B-it.litertlm",
    gpuBackend = GpuBackend.GPU,
    visionBackend = VisionBackend.GPU
)

// Create session
val session = model.createSession()

// Multimodal message with image
val message = Message.user(
    Content.image(imageBytes),
    Content.text("Identify food products and their allergens")
)

// Generate
val response = session.sendMessage(message)
```

Note the clean separation of `gpuBackend` and `visionBackend` — LiteRT-LM handles the vision encoder pipeline internally, similar to how mtmd works in llama.cpp.

## References

- [LiteRT-LM GitHub](https://github.com/google-ai-edge/LiteRT-LM)
- [LiteRT-LM Overview](https://ai.google.dev/edge/litert-lm/overview)
- [Gemma 4 E2B on HuggingFace](https://huggingface.co/google/gemma-4-E2B)
- [Gemma 4 E2B GGUF (Unsloth)](https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF)
- [Gemma 4 for CV Engineers (Datature)](https://datature.io/blog/gemma-4-what-computer-vision-engineers-actually-need-to-know)
- [llama.cpp multimodal docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md)
- [iOS Metal accelerator bug](https://github.com/google-ai-edge/LiteRT/issues/6745)
