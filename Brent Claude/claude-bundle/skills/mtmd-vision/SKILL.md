---
name: mtmd-vision
description: "Use the mtmd (multimodal) C API from llama.cpp for vision inference in Swift/iOS apps. Covers the full pipeline: loading mmproj files, creating bitmaps from images, tokenizing with media markers, running the eval helper, and generating text responses. Use this skill whenever writing or debugging vision/multimodal inference code with llama.cpp — including Qwen3.5 vision, Qwen3-VL, Gemma, LLaVA, or any model that uses mmproj files. Also use when you see mtmd_ function calls, media markers like <__media__>, or questions about multimodal GGUF inference on iOS."
---

# mtmd Vision Inference

mtmd is the multimodal toolkit in llama.cpp. It handles encoding images (and audio) into embeddings that the text model can attend to. The API lives in `mtmd.h` and `mtmd-helper.h`.

## Architecture

```
Image (JPEG/PNG) → mtmd_bitmap → mtmd_tokenize() → chunks (text + image tokens)
    → mtmd_helper_eval_chunks() → logits → sampler → generated text
```

The key insight: mtmd handles the vision encoder internally. You don't manually run CLIP or process image patches. You give it a bitmap and a prompt with a marker, and it returns tokenized chunks that include both text tokens and encoded image embeddings.

## Swift Type Reference

All mtmd types are opaque (forward-declared only):

| C Type | Swift Import | Created By |
|--------|-------------|-----------|
| `mtmd_context *` | `OpaquePointer` | `mtmd_init_from_file()` |
| `mtmd_bitmap *` | `OpaquePointer` | `mtmd_bitmap_init()` or `mtmd_helper_bitmap_init_from_buf()` |
| `mtmd_input_chunks *` | `OpaquePointer` | `mtmd_input_chunks_init()` |
| `const mtmd_input_chunk *` | `OpaquePointer` | from `mtmd_input_chunks_get()` |
| `mtmd_input_text` | `mtmd_input_text` (value type) | manual construction |

## Step 1: Create mtmd Context

```swift
var mtmdParams = mtmd_context_params_default()
mtmdParams.use_gpu = true
mtmdParams.n_threads = Int32(nThreads)
mtmdParams.print_timings = true
// warmup runs a dummy encode pass — set true for production, false for faster startup during dev
mtmdParams.warmup = false

// model is UnsafeMutablePointer<llama_model> from llama_model_load_from_file()
let mtmdCtx: OpaquePointer = mtmd_init_from_file(mmprojPath, model, mtmdParams)!

// Verify vision support (returns false for audio-only models)
guard mtmd_support_vision(mtmdCtx) else { /* handle error */ }
```

The mmproj file is the vision projection model (CLIP-like). It's a separate GGUF file from the main language model.

## Step 2: Create Bitmap from Image

For **file buffers** (JPEG, PNG, BMP, GIF — anything stb_image supports):

```swift
// Best approach: encode UIImage as JPEG data, then pass the raw bytes
let resized = resizeImage(image, maxDimension: 1024)
let jpegData = resized.jpegData(compressionQuality: 0.85)!

let bitmap: OpaquePointer? = jpegData.withUnsafeBytes { rawBuffer in
    let ptr = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
    return mtmd_helper_bitmap_init_from_buf(mtmdCtx, ptr, rawBuffer.count)
}
guard let bitmap else { /* stb_image failed to decode */ }
defer { mtmd_bitmap_free(bitmap) }
```

For **raw RGB data** (no file encoding, already decoded to pixels):

```swift
// data must be nx * ny * 3 bytes, RGBRGBRGB... format
let bitmap = mtmd_bitmap_init(UInt32(width), UInt32(height), rgbPointer)
```

Use the `_from_buf` helper whenever possible — it handles format detection and decoding internally.

### Image Preprocessing

Resize before encoding. Large images use more vision tokens and slow inference significantly.

```swift
func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
    let size = image.size
    let maxSide = max(size.width, size.height)
    guard maxSide > maxDimension else { return image }
    let scale = maxDimension / maxSide
    let newSize = CGSize(width: size.width * scale, height: size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
}
```

Max 1024px on the longest side is a good default. Qwen3.5 uses dynamic resolution — larger images get more tokens (slower but more detail).

You can also limit vision tokens via `mtmdParams.image_max_tokens` if you want to cap processing time regardless of image size.

## Step 3: Tokenize with Media Marker

The prompt must contain a **media marker** where the image should be inserted. The default marker is `<__media__>` (from `mtmd_default_marker()`).

```swift
let marker = String(cString: mtmd_default_marker())
let fullPrompt = "\(marker)\nDescribe what you see in this image."

let chunks: OpaquePointer = mtmd_input_chunks_init()!
defer { mtmd_input_chunks_free(chunks) }

var inputText = mtmd_input_text()
let promptCStr = strdup(fullPrompt)!
defer { free(promptCStr) }
inputText.text = UnsafePointer(promptCStr)
inputText.add_special = true   // add BOS token
inputText.parse_special = true // parse special tokens in the text

// For a single image:
var bitmapPtr: UnsafePointer<mtmd_bitmap>? = UnsafePointer(bitmap)
let result = mtmd_tokenize(mtmdCtx, chunks, &inputText, &bitmapPtr, 1)
// result: 0 = success, 1 = bitmap count mismatch, 2 = image preprocessing error
```

For multiple images, include multiple markers in the prompt and pass an array of bitmap pointers:

```swift
let prompt = "\(marker)\n\(marker)\nCompare these two images."
var bitmaps: [UnsafePointer<mtmd_bitmap>?] = [UnsafePointer(bmp1), UnsafePointer(bmp2)]
let result = mtmd_tokenize(mtmdCtx, chunks, &inputText, &bitmaps, 2)
```

The number of markers in the prompt **must** equal `n_bitmaps`.

## Step 4: Evaluate Chunks

The helper function `mtmd_helper_eval_chunks` does all the heavy lifting — it processes text chunks with `llama_decode` and image chunks with `mtmd_encode` + `llama_decode`, handling batching and non-causal attention setup automatically.

```swift
// Clear KV cache before a new inference
let memory = llama_get_memory(llamaCtx)!
llama_memory_clear(memory, true)

var nPast: Int32 = 0
let evalResult = mtmd_helper_eval_chunks(
    mtmdCtx,
    llamaCtx,      // UnsafeMutablePointer<llama_context>
    chunks,        // from mtmd_tokenize
    nPast,         // starting position (0 for fresh context)
    0,             // seq_id
    512,           // n_batch (process up to 512 tokens at a time)
    true,          // logits_last: compute logits only for the last token
    &nPast         // updated position after eval
)
guard evalResult == 0 else { /* eval failed */ }
```

After this call, the model has processed the entire prompt (text + image) and the logits for the last token are ready for sampling.

## Step 5: Generate Response

Standard llama.cpp token generation loop:

```swift
var output = ""
let maxTokens: Int32 = 4096

for _ in 0..<maxTokens {
    let tokenId = llama_sampler_sample(sampler, llamaCtx, -1)

    if llama_vocab_is_eog(vocab, tokenId) { break }

    // Convert token to string piece
    var buf = [CChar](repeating: 0, count: 256)
    let len = llama_token_to_piece(vocab, tokenId, &buf, 256, 0, false)
    if len > 0 {
        buf[Int(len)] = 0
        output += String(cString: buf)
    }

    // Decode next token
    var token = tokenId
    let batch = llama_batch_get_one(&token, 1)
    let decodeResult = llama_decode(llamaCtx, batch)
    if decodeResult != 0 { break }
}
```

## Cleanup Order

```swift
mtmd_bitmap_free(bitmap)           // free bitmaps when done with them
mtmd_input_chunks_free(chunks)     // free tokenized chunks
// ... later, when unloading:
mtmd_free(mtmdCtx)                 // free mtmd context
llama_sampler_free(sampler)
llama_free(llamaCtx)
llama_model_free(model)
llama_backend_free()
```

Free mtmd context **before** freeing the llama model, since mtmd holds a reference to it.

## Qwen3.5 Vision Specifics

Qwen3.5 is natively multimodal (early fusion). All sizes support vision:

| Model | Main GGUF (Q4_K_M) | mmproj (F16) | Total |
|-------|-------------------|-------------|-------|
| 0.8B | 533 MB | 205 MB | ~738 MB |
| 2B | 1.28 GB | ~665 MB | ~1.95 GB |
| 4B | 2.74 GB | ~665 MB | ~3.4 GB |

- Uses **M-RoPE** (Multi-dimensional Rotary Position Embedding) for spatial understanding
- The VIT (Vision Transformer) is the same as Qwen3-VL's, merged in llama.cpp PR #19468 (Feb 2026)
- Dynamic resolution: larger images get more vision tokens
- OCRBench scores: 0.8B = 74.5, 2B = 84.5 (good for reading ingredient labels)

### Grounding Prompts for Qwen3.5

Qwen3.5 inherits bounding box grounding from the Qwen VL lineage. To get structured detection output:

```
<image>
Identify all food products visible in this image. For each product, provide:
1. A bounding box as normalized coordinates [x, y, width, height] where values are 0-1 relative to image dimensions
2. Whether it contains wheat, soy, both, or neither

Respond in JSON format:
{"products": [{"label": "product name", "bbox": [x, y, w, h], "contains": "wheat|soy|both|neither"}]}
```

The model's grounding accuracy varies — it's best on clearly separated objects and less reliable on dense shelf displays. Fine-tuning the 0.8B model on domain-specific data is the planned v2 improvement.

## Error Handling

| Function | Return | Meaning |
|----------|--------|---------|
| `mtmd_init_from_file` | `NULL` | mmproj file not found, incompatible with model, or OOM |
| `mtmd_tokenize` | 1 | Number of bitmaps doesn't match marker count in prompt |
| `mtmd_tokenize` | 2 | Image preprocessing failed (corrupt image, unsupported format) |
| `mtmd_helper_eval_chunks` | non-zero | encode or decode failed (often OOM or context too small) |
| `mtmd_helper_bitmap_init_from_buf` | `NULL` | stb_image couldn't decode the buffer |

## M-RoPE and Non-Causal Attention

Some models (including Qwen3.5) need special handling during decode:

- **M-RoPE**: Multi-dimensional positional encoding. `mtmd_helper_eval_chunks` handles this automatically by querying `mtmd_decode_use_mrope()` and setting positions correctly.
- **Non-causal attention**: Some vision models need bidirectional attention for image tokens. The helper checks `mtmd_decode_use_non_causal()` and sets the attention mask. If you're using the lower-level API (`mtmd_encode` + manual `llama_decode`), you need to handle this yourself.

The `mtmd_helper_eval_chunks` function is strongly recommended over manual chunk-by-chunk processing because it handles all of these model-specific quirks transparently.
