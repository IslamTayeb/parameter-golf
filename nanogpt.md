# Modded-NanoGPT: Complete Research

## Overview

modded-nanogpt is the NanoGPT speedrun: a collaborative/competitive race to train GPT-2-small to 3.28 validation loss on FineWeb using 8xH100s as fast as possible. Started by Keller Jordan (May 2024), now at record #77.

- Repo: https://github.com/KellerJordan/modded-nanogpt
- Stars: ~5K | Forks: 678 | Commits: 1,599
- Current record: 1.435 minutes (86.1 seconds) — down from 45 minutes baseline
- That's a 31x speedup over 77 records in ~10 months

---

## Record Progression (Track 1: GPT-2 Small)

### Phase 1: Foundations (May-Oct 2024) — Records 1-7 | 45min → 12min

| # | Time | Key Change | Date |
|---|------|-----------|------|
| 1 | 45.0 min | llm.c baseline | 05/28/24 |
| 2 | 31.4 min | Tuned LR + rotary embeddings | 06/06/24 |
| 3 | 24.9 min | Muon optimizer introduced | 10/04/24 |
| 4 | 22.3 min | Muon improvements | 10/11/24 |
| 5 | 15.2 min | Pad embeddings, ReLU^2, zero-init, QK-norm | 10/14/24 |
| 6 | 13.1 min | Distributed Muon overhead | 10/18/24 |
| 7 | 12.0 min | PyTorch 2.5.0 upgrade | 10/18/24 |

Category: Mostly algorithmic (optimizer, architecture). One systems win (distributed Muon, PyTorch upgrade).
Speedup: 3.75x

### Phase 2: Architecture Innovation (Nov 2024) — Records 8-11 | 12min → 7.2min

| # | Time | Key Change | Date |
|---|------|-----------|------|
| 8 | 10.8 min | Untied embedding/head | 11/03/24 |
| 9 | 8.2 min | Value/embedding skip connections, momentum warmup, logit softcap | 11/06/24 |
| 10 | 7.8 min | Bfloat16 activations | 11/08/24 |
| 11 | 7.2 min | U-net skip connections + double LR | 11/10/24 |

Category: Architecture + precision. Bfloat16 activations is a systems optimization.
Speedup: 1.67x

### Phase 3: Long Context Revolution (Nov-Dec 2024) — Records 12-17 | 7.2min → 3.57min

| # | Time | Key Change | Date |
|---|------|-----------|------|
| 12 | 5.03 min | 1024-ctx → 64K-ctx FlexAttention | 11/19/24 |
| 13 | 4.66 min | Attention window warmup | 11/24/24 |
| 14 | 4.41 min | Value Embeddings | 12/04/24 |
| 15 | 3.95 min | U-net value embeddings + code optimizations | 12/08/24 |
| 16 | 3.80 min | Split value embeddings, block sliding window | 12/10/24 |
| 17 | 3.57 min | Sparsify value embeddings, improved rotary, drop attn layer | 12/17/24 |

Category: Algorithmic (attention pattern, embeddings). "Code optimizations" at #15 is the first explicit systems mention at this scale.
Speedup: 2.02x. This is the single biggest phase — FlexAttention alone saved 30%.

### Phase 4: Sub-3-Minute Push (Jan 2025) — Records 18-21 | 3.57min → 2.93min

| # | Time | Key Change | Date |
|---|------|-----------|------|
| 18 | 3.40 min | Lower logit softcap 30→15 | 01/04/25 |
| 19 | 3.14 min | FP8 head, offset logits, lr decay to 0.1 | 01/13/25 |
| 20 | 2.99 min | Merged QKV, long-short attention, batched Muon | 01/16/25 |
| 21 | 2.93 min | Reduced batch size | 01/26/25 |

Category: Mixed. FP8 head = systems (precision). Merged QKV + batched Muon = systems (memory/compute efficiency). Batch size = algorithmic.
Speedup: 1.22x

### Phase 5: Systems Era Begins (May-Sep 2025) — Records 22-37 | 2.99min → 2.48min

THIS IS WHERE THE TREND SHIFTS. Algorithmic gains plateau; systems optimizations dominate.

| # | Time | Key Change | Category | Date |
|---|------|-----------|----------|------|
| 22 | 2.99 min | Faster gradient all-reduce | SYSTEMS | 05/24/25 |
| 23 | 2.98 min | Overlap compute + gradient comms | SYSTEMS | 05/25/25 |
| 24 | 2.97 min | replace all_reduce → reduce_scatter | SYSTEMS | 05/30/25 |
| 25 | 2.90 min | PyTorch 2.9.0 upgrade | SYSTEMS | 07/13/25 |
| 26 | 2.86 min | Align batch starts with EoS | ALGO | 07/13/25 |
| 27 | 2.82 min | Triton symmetric matmul kernel (XXT) | SYSTEMS (KERNEL) | 07/18/25 |
| 28 | 2.81 min | Sparse attention gate | ALGO | 08/23/25 |
| 29 | 2.73 min | Flash Attention 3 | SYSTEMS | 09/03/25 |
| 30 | 2.72 min | Drop first MLP layer | ALGO | 09/05/25 |
| 31 | 2.66 min | YaRN dynamic during training | ALGO | 09/10/25 |
| 32 | 2.63 min | Optimize distributed training, bf16 usage | SYSTEMS | 09/11/25 |
| 33 | 2.57 min | Async data fetch, extend final attn window | SYSTEMS | 09/15/25 |
| 34 | 2.55 min | Smear token embeddings 1 position | ALGO | 09/18/25 |
| 35 | 2.53 min | Drop first attn layer | ALGO | 09/21/25 |
| 36 | 2.50 min | MuonCustomSizing, shared reduce_scatter | SYSTEMS | 09/23/25 |
| 37 | 2.48 min | BF16 cross entropy during training | SYSTEMS | 09/27/25 |

Systems records in this phase: 10 of 16 (63%)
Speedup: 1.20x

### Phase 6: Optimizer + Architecture Polish (Oct-Nov 2025) — Records 38-46 | 2.48min → 2.20min

| # | Time | Key Change | Category | Date |
|---|------|-----------|----------|------|
| 38 | 2.48 min | Polar Express (Newton-Schulz replacement) | ALGO/SYSTEMS | 09/29/25 |
| 39 | 2.45 min | Update Adam every other step, reduce batch | ALGO | 09/30/25 |
| 40 | 2.36 min | Backout (skip from 2/3 to pre-head) | ALGO | 10/04/25 |
| 41 | 2.35 min | NorMuon | ALGO | 10/24/25 |
| 42 | 2.31 min | Update NorMuon LR, step logic | ALGO | 10/27/25 |
| 43 | 2.28 min | Cautious weight decay w/ schedule | ALGO | 11/10/25 |
| 44 | 2.27 min | Backward hooks on Adam (gradient sync overlap) | SYSTEMS | 11/16/25 |
| 45 | 2.25 min | Refine skip arch, exponential decay init | ALGO | 11/18/25 |
| 46 | 2.20 min | Batch size schedule | ALGO | 11/29/25 |

Systems records: 2 of 9 (22%). Optimizer innovation dominant here.
Speedup: 1.13x

### Phase 7: Kernel Fusion Era (Dec 2025 - Jan 2026) — Records 47-62 | 2.20min → 1.66min

THE SYSTEMS RENAISSANCE. Custom Triton kernels start dropping consistently.

| # | Time | Key Change | Category | Date |
|---|------|-----------|----------|------|
| 47 | 2.19 min | Attn lambda on weights, fix warmup | ALGO | 12/10/25 |
| 48 | 2.17 min | Speed up Muon, reshape matrices, NorMuon axis | SYSTEMS | 12/11/25 |
| 49 | 2.15 min | Partial Key Offset | ALGO | 12/14/25 |
| 50 | 2.13 min | Cautious WD on Adam params | ALGO | 12/18/25 |
| 51 | 2.08 min | Retie embed/lm_head, retune FP8 scales | ALGO/SYSTEMS | 12/19/25 |
| 52 | 2.04 min | Smooth scalars, freeze during transitions | ALGO | 12/21/25 |
| 53 | 1.99 min | Multi-token prediction, untie at 2/3 training | ALGO | 12/22/25 |
| 54 | 1.94 min | Asymmetric logit rescale | ALGO | 12/26/25 |
| 55 | 1.92 min | Gates on value embeds + skip connection | ALGO | 12/29/25 |
| 56 | 1.89 min | Optimize+compile Adam, FP32 state, gates→Adam | SYSTEMS | 12/31/25 |
| 57 | 1.88 min | BF16 weights, mixed precision Muon, interweave | SYSTEMS | 01/04/26 |
| 58 | 1.82 min | Paired Head Attention | ALGO | 01/07/26 |
| 59 | 1.78 min | FUSED TRITON KERNEL: linear_relu_square MLP | SYSTEMS (KERNEL) | 01/10/26 |
| 60 | 1.77 min | FUSED TRITON KERNEL: softcapped MTP cross entropy | SYSTEMS (KERNEL) | 01/16/26 |
| 61 | 1.75 min | Unified optimizers + transposed LM head | SYSTEMS | 01/18/26 |
| 62 | 1.66 min | Bigram Hash Embedding | ALGO | 01/19/26 |

Systems records: 7 of 16 (44%). But the BIG drops are kernels:
- #59: Fused linear+relu+square saved 2.8 seconds
- #60: Fused softcapped CE saved 0.9 seconds
Speedup: 1.33x

### Phase 8: Micro-Optimization Endgame (Jan-Mar 2026) — Records 63-77 | 1.66min → 1.44min

| # | Time | Key Change | Category | Date |
|---|------|-----------|----------|------|
| 63 | 1.65 min | Untie value embeds | ALGO | 01/26/26 |
| 64 | 1.63 min | Tuned V/O init | ALGO | 01/30/26 |
| 65 | 1.61 min | Group value embeds into single param | ALGO | 01/30/26 |
| 66 | 1.60 min | Torch 2.10 upgrade | SYSTEMS | 01/31/26 |
| 67 | 1.54 min | Tune fused softcap + fuse FP8 quant in LM head | SYSTEMS (KERNEL) | 01/31/26 |
| 68 | 1.54 min | Move bigram hash to GPU (eliminate H2D) | SYSTEMS | 01/31/26 |
| 69 | 1.53 min | Kernel optimizations (by AI system Aster) | SYSTEMS (KERNEL) | 02/02/26 |
| 70 | 1.52 min | Tune value embed layout | ALGO | 02/03/26 |
| 71 | 1.52 min | Sparse bigram gradient comms | SYSTEMS | 02/06/26 |
| 72 | 1.50 min | Max seq length schedule | ALGO | 02/10/26 |
| 73 | 1.49 min | Partitioned Hyperconnections | ALGO | 02/12/26 |
| 74 | 1.47 min | Flattened forward + transpose kernels | SYSTEMS (KERNEL) | 02/16/26 |
| 75 | 1.45 min | Cross entropy kernel optimizations | SYSTEMS (KERNEL) | 02/23/26 |
| 76 | 1.45 min | Reuse backward transpose kernel | SYSTEMS (KERNEL) | 02/28/26 |
| 77 | 1.44 min | Simplified hyperconnections (single cached activation) | ALGO | 03/06/26 |

Systems records: 9 of 15 (60%). Kernel work dominates the tail.
Speedup: 1.15x (diminishing returns, as expected)

---

## Key Trend Analysis

### Systems vs Algorithmic Records by Phase

| Phase | Period | Records | Systems | Algo | % Systems |
|-------|--------|---------|---------|------|-----------|
| 1 | May-Oct 2024 | 7 | 2 | 5 | 29% |
| 2 | Nov 2024 | 4 | 1 | 3 | 25% |
| 3 | Nov-Dec 2024 | 6 | 1 | 5 | 17% |
| 4 | Jan 2025 | 4 | 2 | 2 | 50% |
| 5 | May-Sep 2025 | 16 | 10 | 6 | 63% |
| 6 | Oct-Nov 2025 | 9 | 2 | 7 | 22% |
| 7 | Dec 2025-Jan 2026 | 16 | 7 | 9 | 44% |
| 8 | Jan-Mar 2026 | 15 | 9 | 6 | 60% |
| TOTAL | | 77 | 34 | 43 | 44% |

### The Crossover Point

Before May 2025 (records 1-21): 6/21 systems records (29%)
After May 2025 (records 22-77): 28/56 systems records (50%)

The competition hit an inflection point around record #22 (May 2025). Once algorithmic innovations saturated (~3 minutes), systems optimizations became the primary source of gains. This exactly mirrors what's happening in Parameter Golf right now (Phase 5: throughput is the bottleneck).

### Diminishing Returns

| Time Range | Records Needed | Days Elapsed |
|-----------|----------------|--------------|
| 45 min → 10 min (78% reduction) | 8 records | ~5 months |
| 10 min → 3 min (70% reduction) | 13 records | ~2 months |
| 3 min → 2 min (33% reduction) | 14 records | ~10 months |
| 2 min → 1.44 min (28% reduction) | 42 records | ~4 months |

The last 28% took 42 records and 4 months of intensive kernel work.

---

## Contributors Who Matter

### Top Systems Contributors

| Contributor | Records | Key Systems Work |
|-------------|---------|-----------------|
| @classiclarryd (ClassicLarry) | 20+ records | MuonCustomSizing, shared reduce_scatter, many arch innovations |
| @YouJiacheng | Records 15-20 | FP8 head, sliding window, early efficiency pioneer |
| @byronxu99 | Record #27 | Symmetric matmul Triton kernel |
| @andrewbriand8 | Records #59, #67 | Fused linear_relu_square, fused FP8 quant |
| @ChrisJMcCormick | Records #56, #61, #74 | Compiled Adam, unified optimizers, transpose kernels |
| @ryanyang0 | Record #23 | Compute/comm overlap |
| @vagrawal | Record #24 | reduce_scatter replacement |
| @KonstantinWilleke + team | Record #22 | Custom AllReduce (Enigma project) |
| @leloykun | Records #15, #20, #21 | Code optimizations, batched Muon, batch size |
| @akash5474 | Record #44 | Adam backward hooks |
| @EmmettBicker + Aster AI | Record #69 | Kernel optimizations via AI agent |
| @moof2x | Record #75 | CE kernel optimization |
| @samacqua | Record #76 | Backward transpose kernel |

### Notable: AI Systems Contributing

- Record #32: @bernard24 & hiverge.ai — distributed training optimization
- Record #60: @soren_dunn_ & Locus (Intology AI) — fused CE kernel
- Record #69: @EmmettBicker & Aster (asterlab.ai) — kernel optimization
- Record #72: @dualverse-ai & Station — seq length schedule

AI agents are now contributing directly to world records.

---

## Track 2: GPT-2 Medium (350M params)

18 records, from 5.8 hours → 17.35 minutes. Notable for:
- Snoo Optimizer (#12): outer optimizer wrapping Adam+Muon
- EMA Wrapper on Muon (#13)
- Smear-MTP (#16)
- Bulk transfer of short track features (#18): single PR brought 5.63 minutes of gains

---

## Relevance to Parameter Golf

### Direct Portables (proven on same hardware)

1. XXT/XTX symmetric Muon kernels → Muon in parameter-golf uses same Newton-Schulz
2. Fused linear_relu_square → parameter-golf uses exact same relu^2 MLP
3. Custom AllReduce / reduce_scatter → parameter-golf uses DDP (opportunity)
4. Compute/gradient comm overlap → parameter-golf has no overlap
5. FP8 LM head → parameter-golf doesn't use FP8
6. Async data prefetch → parameter-golf uses synchronous loading
7. BF16 cross entropy → parameter-golf uses FP32 CE
8. Compiled Adam → parameter-golf Adam is uncompiled
9. Fused FP8 quantization in LM head → directly applicable
10. Sparse gradient comms for bigram hash → parameter-golf now uses BigramHash

### Not Directly Portable (different architecture scale)

- FlexAttention / long-context (parameter-golf is 1024 seq)
- Multi-token prediction (not in parameter-golf baseline)
- Partitioned Hyperconnections (different skip architecture)
- YaRN (different context regime)
- Paired Head Attention (would need new architecture validation)

### Key Insight

modded-nanogpt went through the EXACT same transition that parameter-golf is experiencing now:
1. Algorithmic gains dominate early (everyone discovers the same recipe)
2. Systems gains become the differentiator once recipes converge
3. Custom Triton kernels are the final frontier
4. Communication optimization is free performance
5. Each kernel saves 0.5-3 seconds — these compound

The parameter-golf competition is ~4 days old and in Phase 4-5 (recipe convergence → systems). modded-nanogpt took 10 months to reach the same point. The path is proven.

---

## Change Log
- 2026-03-22 04:30 ET: Initial deep research from full record history, PR history, and kernel source analysis.

---


### Deep Findings: What Actually Worked at Systems Level

#### 1. Kernel Fusion is the #1 Systems Win Category

Total time saved by kernel fusion: ~10.85 seconds across 8 records
- linear_relu_square: -2.8s (#197)
- Fused softcap CE: -0.9s (#199)
- Fused FP8 quant + softcap tuning: -3.1s (#207)
- AI-found kernel optimizations: -1.6s (#217)
- CE kernel optimization: -0.9s (#235)
- Flatten forward + transpose kernels: -1.0s (#233)
- Backward transpose: -0.4s (#240)

That's ~10.85 seconds from kernel work alone. Starting wall time was ~170 seconds when kernel era began (record #27). So kernels delivered ~6.4% of total wall time reduction.

Key techniques within kernels:
- Coalesced memory loads + in-register transpose
- Pre-computed multiplications replacing divisions
- Warp count tuning (4→8 for larger tiles)
- int64 offsets for matrices >2B elements
- TensorDescriptor API (H100 TMA) for zero-copy data movement
- Eliminating `.T.contiguous()` with custom transpose kernels

#### 2. Communication Optimization is #2

Total time saved: ~5-7 seconds across 6 records
- Distributed Muon (#6, record)
- Custom AllReduce (#22, record)
- Compute/grad overlap (#23, record)
- all_reduce → reduce_scatter (#102, record)
- Shared reduce_scatter (#132, -0.7s)
- Adam backward hooks (#149, -0.7s)
- Sparse bigram comms (#221, -0.75s)

Key pattern: EVERY time communication was overlapped with compute or reduced in volume, it worked. No negative results on comm optimization.

#### 3. Precision Optimization is #3

- BF16 activations, weights, CE: cumulative ~3-4 seconds
- FP8 LM head: significant speedup
- Mixed precision Muon with mantissa buffer: critical — "without mantissa tracking, bf16 is substantially detrimental"
- FP32 Adam state: necessary for stability

KEY LESSON: BF16 weights NEED a FP32 mantissa buffer to avoid accuracy loss. This is the most important precision finding.

#### 4. Memory Layout / Data Movement

- Transpose MLP matrix to batch parameters evenly (#109): simple but clever
- Move bigram hash to GPU (#216): eliminate H2D
- Write indices directly to pinned tensors (#221): `.to(device, non_blocking=True)` was "very slow"
- Async data prefetch (#127): overlap with GPU compute
- Flattened forward pass (#233): remove class overhead

#### 5. PyTorch Framework Upgrades

Records #7, #25, #66 were pure PyTorch version bumps:
- 2.5.0: 12.0 → 7.8 min (massive)
- 2.9.0: ~0.07 min savings
- 2.10: ~0.04 min savings

Earlier PyTorch upgrades gave bigger wins. Framework improvements have diminishing returns.

---

### Negative Results Summary — What NOT To Try

1. GQA at small scale: doesn't net positive (step efficiency loss > step time gain)
2. Per-head gradient orthonormalization: too fine-grained, negligible
3. Muon diagonal trick: slightly slower than direct reformulation
4. Compiled Autograd with FlexAttention: broken (as of early 2025)
5. Removing logit softcap: training diverges despite sigmoid being expensive
6. BF16 weights without mantissa buffer: "substantially detrimental"
7. Warmup loops that don't match real training: hides real issues

---

### What's Left on the Table (Open Opportunities)

Based on merged records and negative results, these are UNTRIED or UNDER-EXPLORED:

1. CUDA Graphs for training loop — nobody has tried this in modded-nanogpt
2. Custom NCCL plugins — all comm work used standard NCCL
3. SM-level scheduling — no warp specialization attempted
4. TMA beyond linear_relu_square — only one kernel uses TMA
5. FP4/FP6 matmul — only FP8 and BF16 used
6. Persistent kernels — no kernel persistence attempted
7. Host-device overlap beyond data loading — only PrefetchLoader attempted (#231, still open)
8. Speculative kernel compilation — torch.compile warmup is 7 minutes, not optimized
9. Memory pool management — only one fix (#161) addressed memory waste
10. Custom backward passes — most backward passes still use autograd

---

### AI Systems Contributing to Records

| Record | AI System | Contribution |
|--------|-----------|-------------|
| #32 | hiverge.ai | Vectorized Muon ops, bf16 casting |
| #60 | Locus (Intology AI) | Fused softcapped CE kernel |
| #69 | Aster (asterlab.ai) | Kernel coalesced loads, num_warps tuning |
| #72 | Station (dualverse-ai) | Seq length schedule |

AI agents are now finding real kernel optimizations that humans missed.

---

### Change Log
- 2026-03-22 05:30 ET: Consolidated into single mega file.
- 2026-03-22 05:00 ET: Complete systems PR analysis from modded-nanogpt. Every merged, open, and closed systems PR cataloged with implementation details and lessons learned.


---

# Part 2: Systems-Level Research — Full Source Analysis

Generated from reading actual source code (train_gpt.py 2005 lines, triton_kernels.py 882 lines), every systems PR discussion, and negative results. This is the authoritative reference for porting to parameter-golf.

---

## Architecture of the Current Systems Stack

The current modded-nanogpt is a 2005-line training script with 882 lines of custom Triton kernels. Every systems optimization is production-quality and battle-tested on 8xH100 SXM.

### 1. Custom Triton Kernels (triton_kernels.py)

#### 1.1 XXT — Symmetric Matmul for Muon (lines 35-140)

Purpose: Compute C = A @ A.T exploiting symmetry

How it works:
- Standard tiled matmul but SKIPS blocks below diagonal (upper triangle only)
- After computing each output tile, mirrors it across diagonal via `tl.store` to transposed position
- Uses `tl.trans()` for in-register transpose (PR #217 Aster AI optimization)
- Coalesced loads: loads (BM, BK) and (BN, BK) tiles — both contiguous in K dimension

Key tuning:
- K=768 (Muon): BLOCK 128x128x64, 4 stages, 8 warps
- K!=768: BLOCK 64x128x128, 4 stages, 8 warps
- Warp count increased from 4 to 8 by Aster AI (Record #69) — this alone saved measurable time

Savings: ~50% fewer blocks launched vs naive matmul. The 75% theoretical savings (upper triangle = half) is reduced because some blocks straddle the diagonal.

Critical insight from PR #109 discussion (byronxu99 vs YouJiacheng):
- byronxu99: "75% of the speedup came from batching MLP matrices (24 into 3 groups instead of 4), not from the Triton kernel"
- The kernel itself helps even at small scale, but the REAL win was reducing communication volume by having fewer parameter groups
- YouJiacheng noted reduce_scatter bandwidth on small matrices is only ~200GB/s vs 450GB/s nominal — communication is the bottleneck at this scale

#### 1.2 XTX — Tall Matrix Symmetric Matmul (lines 147-270)

Purpose: Compute C = A.T @ A for tall matrices (MLP weights 3072x768)

How it works: Same diagonal-skip trick but transposed access pattern. Output is small (768x768) but reduction dimension is large (3072).

Used when: Matrix has more rows than columns (Muon's tall MLP weight banks)

#### 1.3 ba_plus_cAA — Fused Newton-Schulz/Polar Express Step (lines 280-410)

Purpose: Compute C = beta*A + alpha*(A @ A.T) in one kernel launch

How it works:
- Same tiled matmul structure as XXT
- Additionally loads a block of A at the same output position
- Multiplies accumulator by alpha, adds beta*A_block
- Mirrors output across diagonal (symmetric)

Why fused: Eliminates intermediate A@A tensor and a separate pointwise add. Two memory round-trips become one.

Critical detail: "Performance is slightly slower than XXT_kernel" per comment — the added load+add makes each tile slightly heavier, but overall win because fewer kernel launches and zero intermediate memory.

#### 1.4 linear_relu_square — Fused MLP Kernel (lines 430-540)

Purpose: Compute relu(x @ W1.T)^2 in a single kernel, for both forward and backward

How it works (FORWARD):
- Standard tiled matmul with TMA (TensorDescriptor API for H100)
- After computing each output tile, applies relu + square IN REGISTER before writing
- Interleaved output: splits accumulator into even/odd halves, processes separately
- Saves aux tensor (pre-activation) for backward

How it works (BACKWARD):
- Loads aux (pre-activation values), computes 2*grad*relu(pre) in-register
- Same tiled structure but with aux_desc.load

TMA (Tensor Memory Accelerator):
- Uses `TensorDescriptor.from_tensor(a, [BLOCK_SIZE_M, BLOCK_SIZE_K])`
- Loads via `a_desc.load([offs_am, offs_k])` instead of manual pointer arithmetic
- Zero-copy: hardware handles address calculation, bounds checking, and caching
- H100-specific feature (SM90)

Performance: 2.3-2.8 seconds saved (Record #59). Profiled with Nsight Systems — eliminated unfused pointwise kernels after GEMM in both forward and backward.

From PR #197 discussion (ClassicLarry): "Is there a reason the second linear is left as its own kernel?" — Yes, W2 matmul has different dimensions and no activation fusion opportunity. Fusing W1+relu+square is the sweet spot.

#### 1.5 Fused Softcapped Cross Entropy (lines 550-820)

Purpose: Compute softcap(logits) + multi-token prediction CE loss + backward in fused kernels

How it works:
- Forward: Computes per-row log-sum-exp over softcapped logits, then gathers target logits
- Softcap: z = A * sigmoid(logit/C + B/C) — replaces separate tanh-based softcap
- Backward: Computes gradient including FP8 quantization of the gradient for LM head backward
- Fused FP8 quant in LM head backward (PR #207): divides gradient by grad_s and casts to float8_e5m2 INSIDE the kernel

Key optimization from PR #207 (andrewbriand):
- Set num_warps=2 on softcap forward kernel (was likely autotuned wrong)
- Fused FP8 quantization into backward — saves one full read+write pass over the gradient tensor
- "Tried removing logit softcapping since sigmoid is expensive, but training diverged" — sigmoid is REQUIRED despite being slow

From PR #235 (moof2x): Further CE kernel optimization saved another 0.9 seconds.

From PR #240 (samacqua): Backward transpose kernel — `tl.trans(tile)` in Triton replaces `.T.contiguous()` which was launching a separate 75k-block elementwise kernel with non-coalesced reads. int64 offsets needed because the 49152x50304 logit matrix exceeds int32 range.

#### 1.6 transpose_copy and transpose_add (lines 660-810)

Purpose: Efficient transpose operations for tied embeddings

transpose_copy: dst = src.T
- 64x128 tiles, 8 warps, 2 stages
- Coalesced reads from src(M,N), coalesced writes to dst(N,M) using tl.trans()
- Replaces PyTorch's separate copy + transpose

transpose_add: dst += src.T
- 32x32 tiles, 4 warps, 2 stages
- Read src tile, read dst tile, add tl.trans(src_tile) to dst_tile, write back
- Replaces `dst.add_(src.T)` which has non-coalesced reads

Why these matter: When embed and lm_head are tied, every optimizer step needs lm_head.data.T copied to embed.data. With 50304x768 matrix, the transpose is ~154MB — non-coalesced access hurts badly.

---

### 2. Communication Optimizations

#### 2.1 The Evolution: DDP → reduce_scatter → sharded optimizer

Phase 1 (baseline): Standard DDP all_reduce on gradients
Phase 2 (Record #22-24): Replaced all_reduce with reduce_scatter
- Each GPU only gets 1/8 of the gradient
- Each GPU updates its 1/8 shard of the parameter
- Then all_gather to reassemble the full parameter
- Saves 7/8 of gradient communication bandwidth

Phase 3 (Record #36): Shared reduce_scatter
- All attention and MLP weights reshaped into "parameter banks"
- attn_bank: (N_attn * num_heads * head_dim, model_dim) — one big matrix
- mlp_bank: (N_mlp * 2 * mlp_dim, model_dim) — one big matrix
- Constraint: (n_attn + n_mlp*2) % 4 == 0 — must divide evenly across 8 GPUs
- ONE reduce_scatter call for all attention weights, ONE for all MLP weights
- vs. previous: N separate reduce_scatter calls

#### 2.2 Adam Backward Hooks (Record #44, PR #149)

The idea: Don't wait for full backward pass to start gradient sync

Implementation:
- Register backward hooks on Adam parameters
- When gradient is ready for a layer, immediately launch reduce_scatter
- Process parameters in reverse layer order for maximum overlap

From PR discussion: "Trigger gradient communication during backward pass" — this is standard overlap, but the implementation was non-trivial because Muon needs full gradient before it can start (Newton-Schulz operates on the whole matrix).

#### 2.3 Explicit Scatter/Work Ordering

Current implementation uses explicit `scatter_order` and `work_order` lists:

scatter_order (launch order):
1. bigram_embed (sparse, must start early)
2. embed, value_embeds, attention scalars/gates (small, fast)
3. lm_head (medium)
4. attn_bank, mlp_bank (large, need polar express — process last)

work_order (computation order):
1. bigram_embed (sparse merge is complex)
2. sa_lambdas, attn_gate_bank, ve_gate_bank (small, fast updates)
3. value_embeds (medium)
4. lm_head, embed (must finish lm_head before embed sync when tied)
5. attn_bank, mlp_bank (large, polar express — process last to maximize overlap)

This explicit ordering means communication for early-scattered params overlaps with computation of later params.

#### 2.4 Sparse Bigram Communications (Record #71, PR #221)

Problem: Bigram embedding is 50304*5 = 251,520 rows, but only ~5-15% are touched per batch.

Solution:
1. Track which bigram rows were touched (numpy mask, CPU)
2. `sparse_comms_start`: Count touched rows per rank shard, share counts via all_to_all_single
3. `sparse_comms_share_indexes`: Share which row indices each rank needs
4. `sparse_comms_share_gradients`: Gather only touched rows, all_to_all_single with variable split sizes
5. `sparse_comms_merge_gradients`: index_add_ received rows into local gradient

Critical implementation detail from PR #221 (shenberg):
- First attempt (#219) was "too messy" and closed
- `.to(device, non_blocking=True)` on the index tensor was "very slow" — replaced with pinned tensor + direct copy
- Own rank's send-count set to 0 — avoids sending your own gradient rows to yourself
- This is a ~75% reduction in bigram gradient communication volume

#### 2.5 Negative Result: Compiled Autograd (PR #97)

xmfan (from the PyTorch team) tried Compiled Autograd to overlap DDP AllReduce with backward compute.

Result: Never submitted. Compatibility issues with FlexAttention.

YouJiacheng's insight: "Exposed comm time is usually over-estimated because first collectives have 3-4ms extra latency from uneven workload." The communication time people measure includes one-time warmup costs that don't repeat.

---

### 3. Precision Engineering

#### 3.1 BF16 Weights with Mantissa Buffer (Record #57, PR #190)

This is THE most important precision finding.

Problem: Storing weights in BF16 saves memory and speeds up matmul, but BF16 has only 7 mantissa bits vs FP32's 23. Small updates get rounded to zero.

Solution: Store an additional uint16 "mantissa buffer" per weight:
```
# Reconstruct FP32 from BF16 + mantissa:
p_precise_raw = (p.to(uint32) << 16) | mantissa.to(uint32)
p_precise = p_precise_raw.view(float32)

# After update, split back:
p.copy_((p_precise_raw >> 16).to(uint16))  # upper 16 bits = BF16
mantissa.copy_(p_precise_raw.to(uint16))    # lower 16 bits = mantissa
```

This is BF16 storage with FP32 update precision. The weight is physically BF16 (fast matmul, less communication), but the optimizer sees FP32 precision.

From PR #190 (ClassicLarry): "Without the mantissa tracking the bfloat16 update is substantially detrimental to loss." The loss curves diverge significantly without it.

Memory cost: +2 bytes per Muon parameter (the mantissa buffer). But saves 2 bytes on the weight itself (FP32→BF16), so net zero for Muon params. Adam params don't use mantissa.

#### 3.2 FP8 Matmul for LM Head (Records #19, #67)

Implementation:
- Custom op `nanogpt::mm_t` wraps `torch._scaled_mm`
- Forward: x.div(x_s).to(float8_e4m3fn), w.div(w_s).to(float8_e4m3fn)
- Column-major trick: `w_f8.T.contiguous().T` creates column-major view for _scaled_mm
- Backward: Gradient quantized to float8_e5m2 (less precision, more range)
- FP8 scales hardcoded per layer: x_s=1.0, w_s=1.0, grad_s=1.0 for LM head

Fused FP8 quant in CE backward (PR #207): The gradient is divided by grad_s and cast to float8 INSIDE the softcapped CE backward kernel, saving a full pass over the gradient tensor.

#### 3.3 BF16 Cross Entropy (Record #37, PR #133)

Switched loss computation from FP32 to BF16. Surprisingly, this doesn't hurt convergence at all. The loss value only needs to be accurate enough to compute useful gradients — BF16 precision is sufficient.

#### 3.4 Compiled Adam (Record #56, PR #187)

```python
@torch.compile(dynamic=False, fullgraph=True)
def _adam_update_step(p_slice, g_slice, exp_avg, exp_avg_sq, ...):
```

`dynamic=False` is critical — "Must use dynamic=False or else it's much slower." This prevents recompilation when tensor shapes change.

Adam state (exp_avg, exp_avg_sq) kept in FP32 even though weights are BF16. The 0-D CPU tensors (`self._step_size_t`, `self._eff_wd_t`) prevent recompilation when hyperparameters change.

---

### 4. Data Movement

#### 4.1 Async Data Prefetch (Record #33, PR #127)

```python
@staticmethod
def load_async(file: Path, world_size: int = 1):
    result = {}
    ready = threading.Event()
    def load():
        tokens = _load_data_shard(file)
        result['shard'] = Shard(tokens, world_size)
        ready.set()
    thread = threading.Thread(target=load)
    thread.start()
```

Loads next data shard in a background thread while GPU is training. Uses `threading.Event()` for synchronization.

Data tensors transferred with `non_blocking=True`: `_inputs.to(device="cuda", non_blocking=True)`

Also: inputs cast to int32 on CPU before transfer to avoid dtype conversion during `.to()`.

#### 4.2 Bigram Hash on GPU (Record #68, PR #216)

Moved bigram hash computation from CPU to GPU. Previously: compute on CPU, transfer result. Now: transfer raw tokens, compute hash on GPU.

But there's a subtlety — the bigram hash is ALSO needed on CPU for sparse comms (numpy indexing). So the current code computes it on CPU with pinned memory AND sends raw tokens to GPU:
```python
_bigram_inputs = get_bigram_hash(_inputs)
yield (
    _inputs.to(device="cuda", non_blocking=True),
    ...
    _bigram_inputs.to(device="cuda", non_blocking=True),
    _bigram_inputs.numpy(),  # CPU copy for sparse comms
)
```

#### 4.3 Transposed Weight Storage (Records #74, PR #233)

`CastedLinearT` stores weights as (in_features, out_features) instead of standard (out_features, in_features).

Why: "Addresses the slow kernel that was used for gradient accumulation" (ChrisMcCormick). When accumulating gradients into a transposed weight, PyTorch launches a slow elementwise kernel with non-coalesced access. Storing transposed avoids this.

Forward: `x @ self.weight.type_as(x)` — standard matmul, weight is already in correct layout.

---

### 5. Training Loop Architecture

#### 5.1 Warm-Up and Compilation

```python
print0("Compiling model and warming up kernels (~7 minutes on first execution)")
```

Takes 7 MINUTES to compile. This is NOT counted in the training time.

`dynamo.config.recompile_limit = 64` — allows many recompilations (default is much lower).

`torch._inductor.config.coordinate_descent_tuning = True` is BANNED — "causes compilation to take 30min."

A dummy backward pass is run at import time to prevent a CUDA bug:
```python
torch.empty(1, device=f"cuda:{os.environ['LOCAL_RANK']}", requires_grad=True).backward()
```

#### 5.2 Adam Every Other Step (Record #39)

Adam parameters only update on odd steps. Muon always updates.

`do_adam = step % 2 == 1`

This halves Adam communication overhead with minimal accuracy loss. Works because embedding/gate weights change slowly relative to attention/MLP weights.

#### 5.3 Embed/LM Head Tying and Splitting

Embeddings and LM head are TIED for the first 2/3 of training, then split.

When tied:
- Only lm_head gradient is communicated (embed.grad.T is added via transpose_add kernel)
- After optimizer update, lm_head.data.T is copied to embed.data via transpose_copy kernel
- This halves the communication for the largest parameter

At split point:
- Full lm_head optimizer state is all-gathered, transposed, and re-sharded for embed
- Complex because sharding dimensions differ: lm_head (768, 50304) sharded along dim 0, embed (50304, 768) sharded along dim 0
- After split, both are independently updated

---

### 6. Negative Results — Detailed Analysis

#### 6.1 GQA at Small Scale (PR #49)

Tried: Grouped Query Attention — share key/value heads across query heads

Results:
- 14% per-step speedup (fewer key/value projections)
- BUT 8% more steps needed to reach same loss
- Net: ~6% wallclock improvement initially
- BUT: YouJiacheng found most gain came from smaller value embeddings, not GQA itself
- On proper H100 SXM (not NVL): only ~1% improvement

Lesson: At small model scale (768 dim), the computation savings from GQA don't compensate for reduced model capacity. GQA wins only appear at larger scale.

Relevance to parameter-golf: Parameter-golf uses GQA (4 KV heads, 8 attn heads). This suggests GQA might actually be HURTING them at this scale. But they can't change it (baseline is fixed).

#### 6.2 Per-Head Gradient Orthonormalization (PR #47)

Tried: Run Newton-Schulz at per-attention-head granularity instead of per-layer

Result: Only 1% speedup on 1xH100. Not worth the complexity.

Lesson: Finer-grained orthogonalization doesn't help at 768-dim scale.

#### 6.3 Algebraic Muon Rewrite (PR #16)

Tried: Rewrite Muon's Newton-Schulz to minimize operations via algebraic identities, including a "diagonal trick"

Results:
- Saved <1 second on 125M model
- The diagonal trick specifically was "somewhat slower"
- Keller eventually adopted a different algebraic approach (Polar Express)

Lesson: The implementation (kernel launches, memory access patterns) matters more than the algebra. Polar Express succeeded where PR #16 failed because it found better coefficients, not better algebra.

#### 6.4 Compiled Autograd + FlexAttention (PR #97)

Tried: Use PyTorch's Compiled Autograd to automatically overlap backward computation with gradient communication

Result: Compatibility issues with FlexAttention. Never submitted.

YouJiacheng's insight: "Exposed communication time is usually over-estimated because first collectives have 3-4ms extra latency from uneven workload." Real overlap opportunity is smaller than profiling suggests.

#### 6.5 Turbo-Muon: AOL Preconditioning (PR #155)

Tried: Use AOL (Approximate Online Learning) preconditioning to remove one Newton-Schulz iteration

Finding: Preconditioning helps the FIRST NS iteration (not the last as expected). Removing the first iteration with preconditioning is the right approach.

Result: Never validated on 8xH100 (no access). Still open opportunity.

#### 6.6 Removing Logit Softcap (PR #207 discussion)

Tried: Remove sigmoid-based softcap since sigmoid is expensive

Result: Training diverges. Softcap is mathematically necessary for stable training.

Lesson: Some "expensive" operations are non-negotiable. The right approach is fusing them into adjacent kernels, not removing them.

#### 6.7 BF16 Weights Without Mantissa (PR #190)

Tried: Store weights in BF16 without tracking low bits

Result: "Substantially detrimental to loss." Loss curves diverge significantly.

Lesson: 7-bit mantissa is not enough precision for gradient updates. You MUST track the lower 16 bits separately. This is a ~0 memory-cost trick (swap FP32 weight for BF16 weight + uint16 mantissa).

---

### 7. Open Opportunities (Untried in modded-nanogpt)

Based on exhaustive PR analysis, these are CONFIRMED untried:

1. CUDA Graphs for training loop
   - Nobody has attempted this despite it being a standard optimization
   - Reason: Dynamic control flow (batch size schedule, window size changes, Adam-every-other-step) makes it hard
   - Opportunity: Use CUDA Graphs for the inner loop iterations where nothing changes

2. Custom NCCL plugins or Ring-AllReduce
   - All communication uses standard NCCL via torch.distributed
   - Custom ring AllReduce could exploit NVLink topology better for small messages

3. Warp-Specialized Attention Kernels
   - Using FlashAttention 3 as-is (prebuilt kernel)
   - No custom attention kernels written for the specific head_dim=128, num_heads=6 configuration
   - At 768-dim with 6 heads, the tile sizes may not be optimal for FA3 defaults

4. TMA Beyond linear_relu_square
   - Only 1 of 7 kernels uses TMA (TensorDescriptor API)
   - XXT, XTX, ba_plus_cAA all use manual pointer arithmetic
   - TMA could speed these up by offloading address computation to hardware

5. Persistent Kernels
   - No kernel uses persistent grid strategy (loop over tiles within a single launch)
   - linear_relu_square uses it (loop over tiles with `for tile_id in tl.range(start_pid, num_tiles, NUM_SMS)`)
   - But XXT/XTX/ba_plus_cAA don't — they launch one CTA per tile

6. FP4 Training
   - Only FP8 and BF16 used
   - NVIDIA H100 supports FP4 (as of CUDA 12.8)
   - Could try FP4 for less critical matmuls

7. Custom Backward Passes
   - Most backward computation uses autograd + torch.compile
   - Only MLP and CE have custom backward kernels
   - Attention backward is entirely autograd (through FA3)

8. Memory Pool Management
   - Only one fix (#161) addressed memory waste
   - `expandable_segments:True` is set but no further memory pool tuning
   - No explicit memory pre-allocation or tensor reuse

9. Torch.compile Warmup Optimization
   - 7-minute compilation time is accepted as-is
   - No use of AOTAutograd caching or persistent compilation cache
   - For competitions: could pre-compile offline

10. Pipeline Parallelism
    - Pure data parallelism (DDP-like with reduce_scatter)
    - No tensor parallelism or pipeline parallelism
    - At 768-dim, TP overhead likely exceeds benefit

---

### 8. Key Numbers and Timings

Current state (Record #77, 1.44 minutes = 86.4 seconds):
- Model: 11L, 768-dim, 6 heads, head_dim=128
- 1450 scheduled + 40 extension = 1490 total steps
- Step time: ~58ms (derived from 86.4s / 1490 steps)
- Training tokens: ~11B (8 * 524K * 1490 * grad_accum)
- Compilation: ~7 minutes (not counted)

Kernel timings (from Nsight profiling, PR #197):
- Fused linear_relu_square forward: ~X ms (saved 2.8s total across training)
- Fused softcapped CE: saved 0.9s
- XXT/XTX + ba_plus_cAA per Polar Express iteration: sub-ms each
- Polar Express total per step: ~few ms (3 iterations of XXT/ba_plus_cAA)

Communication timings (from PR #109 discussion):
- AllGather bandwidth on small matrices: ~200GB/s (vs 450GB/s nominal NVLink)
- This means communication is ~2.25x slower than theoretical peak for small tensors
- reduce_scatter is faster than all_reduce for sharded optimizer

---

### 9. Portability Map to Parameter-Golf

| modded-nanogpt Optimization | parameter-golf Equivalent | Difficulty | Expected Gain |
|------------------------------|--------------------------|------------|---------------|
| XXT/XTX symmetric Muon | Direct port — same Newton-Schulz | LOW | 1-2% step time |
| ba_plus_cAA fused NS | Direct port — same coefficients | LOW | 0.5-1% step time |
| linear_relu_square | Direct port — same relu^2 MLP | MEDIUM | 3-5% step time |
| Fused softcapped CE | Not applicable — different CE | — | — |
| transpose_copy/add | Applicable if tying embed/lm_head | LOW | <1% step time |
| reduce_scatter optimizer | Replace DDP with sharded optimizer | MEDIUM | 5-10% step time |
| Sparse bigram comms | Direct port — parameter-golf uses BigramHash | MEDIUM | 2-5% step time |
| BF16 weights + mantissa | Direct port to Muon params | LOW | 3-8% step time |
| FP8 LM head | Direct port | MEDIUM | 2-4% step time |
| BF16 CE | Direct port | LOW | 0.5-1% step time |
| Compiled Adam | Direct port | LOW | 1-2% step time |
| Async data prefetch | Direct port | LOW | 1-3% step time |
| Adam every other step | Direct port | LOW | 1-2% comm savings |
| Explicit scatter/work ordering | Requires optimizer rewrite | HIGH | 5-10% step time |
| Parameter banking (shared reduce_scatter) | Requires architecture alignment | HIGH | 3-5% comm savings |

Compounded estimate: Tier 1 (LOW difficulty) = 10-20% step time reduction. All tiers = 30-50%.

---

### 10. Change Log

- 2026-03-22 05:00 ET: Full source analysis of train_gpt.py (2005 lines) and triton_kernels.py (882 lines). Every systems PR read with discussion comments. 7 negative results documented with reasons. 10 untried opportunities identified.
