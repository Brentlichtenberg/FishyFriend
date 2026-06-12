---
name: llama-cpp-ios
description: "Integrate llama.cpp into iOS/macOS Xcode projects — building from source with CMake, creating XCFrameworks with mtmd (multimodal) support, setting up module maps for Swift interop, and writing correct Swift code against the llama.cpp C API. Use this skill whenever working with llama.cpp in an Apple platform project: adding the dependency, fixing build errors, writing inference code, updating the framework after pulling new llama.cpp changes, or debugging linker/module issues. Also use when you see `import llama_cpp` in Swift code or references to GGUF models in an iOS context."
---

# llama.cpp iOS Integration

## Building from Source

The official XCFramework (`build-xcframework.sh`) does **not** include mtmd (the multimodal/vision library). To get mtmd support, build from source with CMake.

### Build Script Pattern

Clone llama.cpp into `vendor/llama.cpp`, then build for each platform:

```bash
cmake -S vendor/llama.cpp -B build/$PLATFORM-arm64 \
    -G "Unix Makefiles" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$(xcrun --sdk $SDK --show-sdk-path)" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=18.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_TOOLS=ON \       # required for mtmd
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_METAL=ON \
    -DLLAMA_METAL_EMBED_LIBRARY=ON \
    -DGGML_METAL=ON \
    -DGGML_METAL_EMBED_LIBRARY=ON

cmake --build build/$PLATFORM-arm64 --target llama mtmd ggml -- -j$(sysctl -n hw.ncpu)
```

Build for both `iphonesimulator` and `iphoneos`, then combine static libs:

```bash
xcrun libtool -static -o libllama_all.a \
    src/libllama.a \
    ggml/src/libggml.a \
    ggml/src/libggml-base.a \
    ggml/src/libggml-cpu.a \
    ggml/src/ggml-metal/libggml-metal.a \
    tools/mtmd/libmtmd.a
```

Create the XCFramework:

```bash
xcodebuild -create-xcframework \
    -library build/sim-framework/libllama_all.a -headers build/sim-framework/include \
    -library build/device-framework/libllama_all.a -headers build/device-framework/include \
    -output Frameworks/llama.xcframework
```

### Required Headers

Copy these into the framework's `include/` directory:

From `include/`: `llama.h`
From `ggml/include/`: `ggml.h`, `ggml-alloc.h`, `ggml-backend.h`, `ggml-metal.h`, `ggml-cpu.h`, `ggml-opt.h`, `gguf.h`
From `tools/mtmd/`: `mtmd.h`, `mtmd-helper.h`

### Module Map

Place this in each platform's `Headers/` directory as `module.modulemap`:

```
module llama_cpp {
    header "llama.h"
    header "ggml.h"
    header "ggml-alloc.h"
    header "ggml-backend.h"
    header "ggml-metal.h"
    header "ggml-cpu.h"
    header "ggml-opt.h"
    header "gguf.h"
    header "mtmd.h"
    header "mtmd-helper.h"
    export *
}
```

Then `import llama_cpp` works in Swift.

### Known Header Patches

**mtmd-helper.h line 52**: `mtmd_decoder_pos` is used without `struct` tag. The Clang module builder requires it. Patch both platform copies:

```
// Before (breaks):
MTMD_API void mtmd_helper_image_get_decoder_pos(... mtmd_decoder_pos * out_pos);
// After (works):
MTMD_API void mtmd_helper_image_get_decoder_pos(... struct mtmd_decoder_pos * out_pos);
```

Add this patch to the build script after copying headers.

## Xcode Project Integration

### Linking Requirements

The target's `OTHER_LDFLAGS` must include:

```
-framework Metal
-framework MetalKit
-framework Accelerate
-framework Foundation
-lc++
```

These are needed because llama.cpp uses Metal for GPU compute, Accelerate for BLAS, and is written in C++.

### Adding the XCFramework

In the pbxproj:
1. Add a `PBXFileReference` for `llama.xcframework` (lastKnownFileType = wrapper.xcframework)
2. Add a `PBXBuildFile` referencing it in the Frameworks build phase
3. Add a `PBXGroup` for the Frameworks directory
4. The framework goes in `PBXFrameworksBuildPhase.files`

## Swift Type Mappings

The llama.cpp C API uses **opaque struct pointers**. In Swift, these import as `UnsafeMutablePointer<StructName>` (or `OpaquePointer` only if the struct definition is completely hidden). Here are the actual types:

| C Type | Swift Type | Notes |
|--------|-----------|-------|
| `struct llama_model *` | `UnsafeMutablePointer<llama_model>` | From `llama_model_load_from_file()` |
| `struct llama_context *` | `UnsafeMutablePointer<llama_context>` | From `llama_init_from_model()` |
| `const struct llama_vocab *` | `UnsafePointer<llama_vocab>` | From `llama_model_get_vocab()` |
| `struct llama_sampler *` | `UnsafeMutablePointer<llama_sampler>` | From `llama_sampler_chain_init()` |
| `llama_memory_t` | `OpaquePointer` | This one IS opaque (`typedef struct llama_memory_i *`) |
| `mtmd_context *` | `OpaquePointer` | Opaque (only forward-declared) |
| `mtmd_bitmap *` | `OpaquePointer` | Opaque |
| `mtmd_input_chunks *` | `OpaquePointer` | Opaque |
| `mtmd_input_chunk *` | `OpaquePointer` | Opaque |
| `struct llama_batch` | `llama_batch` | Value type (struct), not a pointer |
| `llama_token` | `Int32` | typedef of int32_t |
| `llama_pos` | `Int32` | typedef of int32_t |
| `llama_seq_id` | `Int32` | typedef of int32_t |

The key distinction: `llama_model`, `llama_context`, `llama_sampler`, and `llama_vocab` are **forward-declared structs** in the header (e.g., `struct llama_sampler { ... }` is defined with visible members), so Swift imports pointers to them as `UnsafeMutablePointer<llama_sampler>`. The mtmd types are truly opaque (only forward-declared, never defined in the public header), so they import as `OpaquePointer`.

**Do not use `OpaquePointer` for llama_model, llama_context, llama_sampler, or llama_vocab.** The compiler will reject conversions between `OpaquePointer` and `UnsafeMutablePointer<llama_sampler>`.

## Core API Patterns in Swift

### Model Loading

```swift
llama_backend_init()

var modelParams = llama_model_default_params()
#if targetEnvironment(simulator)
modelParams.n_gpu_layers = 0  // no Metal on simulator
#else
modelParams.n_gpu_layers = 999  // offload all layers
#endif

let model: UnsafeMutablePointer<llama_model> = llama_model_load_from_file(path, modelParams)!
let vocab: UnsafePointer<llama_vocab> = llama_model_get_vocab(model)!
```

### Context Creation

```swift
var ctxParams = llama_context_default_params()
ctxParams.n_ctx = 4096                        // uint32_t
ctxParams.n_threads = Int32(nThreads)         // int32_t
ctxParams.n_threads_batch = Int32(nThreads)   // int32_t

let ctx: UnsafeMutablePointer<llama_context> = llama_init_from_model(model, ctxParams)!
```

### Sampler Chain

```swift
let sparams = llama_sampler_chain_default_params()
let sampler: UnsafeMutablePointer<llama_sampler> = llama_sampler_chain_init(sparams)!
llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.1))
llama_sampler_chain_add(sampler, llama_sampler_init_dist(42))
```

### KV Cache Clear

```swift
// There is NO llama_kv_self_clear or llama_kv_cache_clear.
// Use llama_memory_clear on the memory object:
let memory = llama_get_memory(ctx)!
llama_memory_clear(memory, true)
```

### Token Generation Loop

```swift
let tokenId = llama_sampler_sample(sampler, ctx, -1)

if llama_vocab_is_eog(vocab, tokenId) { break }

var buf = [CChar](repeating: 0, count: 256)
let len = llama_token_to_piece(vocab, tokenId, &buf, 256, 0, false)
if len > 0 {
    buf[Int(len)] = 0
    let piece = String(cString: buf)
}

// Feed token back for next generation
var token = tokenId
let batch = llama_batch_get_one(&token, 1)
llama_decode(ctx, batch)
```

### Cleanup

```swift
llama_sampler_free(sampler)   // frees the whole chain
llama_free(ctx)               // frees context
llama_model_free(model)       // frees model
llama_backend_free()          // global cleanup
```

Free in reverse order of creation. Do not free individual samplers that were added to a chain — the chain owns them.

## Simulator vs Device

- **Simulator (arm64)**: Metal compute shaders DO work on Apple Silicon simulator runtimes, but `n_gpu_layers = 0` is safer for testing since the simulator's Metal implementation can be flaky with compute-heavy workloads.
- **Device (arm64)**: Set `n_gpu_layers = 999` to offload everything to the GPU via Metal. This is dramatically faster.
- Use `#if targetEnvironment(simulator)` to switch.

## Memory Management

- Monitor with `os_proc_available_memory()` before loading models
- Unload models when app enters background (`scenePhase` observer)
- The 2B Q4_K_M model (~1.3 GB) fits comfortably on 6 GB devices
- The 4B Q4_K_M model (~2.7 GB) needs 8 GB+ RAM
