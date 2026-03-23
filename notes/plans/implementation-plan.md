# 2026-03-22 — Comprehensive Research & Execution Plan

Sources: full-text reading of 8 key papers (22 total verified), all 174 scored
competition submissions from `tracker.md`, empirical systems data from
`notes/research/systems-consolidated.md`, and exact parameter counts from
`train_gpt.py`.

**Important framing from the consolidated notes (line 283):** "papers are useful for
scouting ideas, but the repo's own measurements should dominate prioritization." All
bpb impact estimates below are derived from competition leaderboard deltas, not from
our repo. They are hypotheses until we measure them ourselves.

---

## 0. Where We Are and Where We Need To Be

### Current baseline
- 9 layers, 512 dim, 2x MLP (hidden=1024), 8 heads / 4 KV heads
- **17,059,912 total parameters** (17.06M)
- int8 per-row quantization + zlib-9 compression
- Baseline val_bpb: ~1.2244 (confirmed leaderboard rank 14, the starting baseline)
- No XSA, no BigramHash, no SmearGate, no SWA/EMA, no sliding eval, no TTT
- Kaiming init (not orthogonal), full RoPE, no LN Scale

### Current SOTA (PR #374, unnir)
- 11L + Tight SWA + Shared VE128 + Partial RoPE + LN Scale + XSA4
- **val_bpb: 1.1246**

### Target: competitive submission (~1.13 or better)

### Gap to close: ~0.10 bpb

The competition meta (Phase 5, per tracker) says: "Recipe commoditized. Edge comes from
systems optimization, eval tricks, or smart quant." This means the techniques below are
well-documented by other entries — the question is execution quality and throughput.

---

## 1. Byte Budget Math (THE HARD CONSTRAINT)

The 16 MB cap is 16,000,000 bytes total (code + compressed model). Code is ~50-80KB.
So we have ~15,920,000 bytes for the compressed model.

### Current baseline (9L / 2x MLP / int8+zlib)

Per block:
- Attention: c_q(512,512) + c_k(256,512) + c_v(256,512) + proj(512,512) = 786,432 matrix params
- MLP: fc(1024,512) + proj(512,1024) = 1,048,576 matrix params
- Scalars: attn_scale(512) + mlp_scale(512) + resid_mix(2,512) + q_gain(8) = 2,048
- **Per block total: 1,837,056 params**

Global:
- tok_emb(1024,512) = 524,288 params
- skip_weights(4,512) = 2,048 params
- **Total: 524,288 + 2,048 + 9 * 1,837,056 = 17,059,840 params**

At int8 (1 byte/param for matrices + 2 bytes/param for fp16 row scales):
- Matrix params per block: 1,834,880 (all the CastedLinear weights)
- int8 payload per block: 1,834,880 * (1 + 2/row_length) ≈ 1,834,880 * 1.004 ≈ 1,842,220 bytes
- 9 blocks: ~16.58M int8 payload
- After zlib-9: typically ~65-70% of payload → ~10.8-11.6M compressed

So current baseline fits comfortably. But 11L/3xMLP is bigger.

### Target config (11L / 3x MLP / int6+zstd)

Per block with 3x MLP (hidden=1536):
- Attention: same 786,432 matrix params
- MLP: fc(1536,512) + proj(512,1536) = 786,432 + 786,432 = 1,572,864 matrix params
- **Per block matrix params: 2,359,296**
- Scalars: ~2,048 (same)

Global:
- tok_emb(1024,512) = 524,288
- skip_weights(5,512) = 2,560 (11L: encoder=5, decoder=6, min=5)
- **Total: 524,288 + 2,560 + 11 * 2,361,344 = 26,501,632 params (~26.5M)**

**IMPORTANT:** int5 (values in [-15,15]) and int6 (values in [-31,31]) are stored as
int8 tensors (1 byte per param). The savings come from zstd compressing the smaller
value range much better, NOT from smaller per-element storage.

At int8 storage (1 byte/param + fp16 row scales):
- Per block raw: 2,359,296 matrix bytes + ~7,168 scale bytes ≈ 2,366,464 bytes
- 11 blocks: ~26.03M bytes
- tok_emb (int8): ~526K bytes
- Small tensors (fp16/fp32 control): ~55K bytes
- **Total raw payload: ~26.61M bytes**

zstd-22 compression on int5/int6 values (restricted range → lower entropy):
- At 55% compression: **14.64M bytes** ← fits with ~1.3M headroom
- At 60% compression: **15.97M bytes** ← fits with ~30K headroom (TIGHT)
- At 65% compression: **17.30M bytes** ← DOES NOT FIT

PR #272 (simon-marcus) confirms: "mixed int5/int6 export reaches ~10.4MB" — that's
at a very good compression ratio, likely with aggressive weight decay helping.

**With BigramHash(10240, 512) embeddings:**
- 10240 * 512 = 5,242,880 extra params → ~5.26M bytes raw
- Total raw with BigramHash: ~31.88M bytes
- At 55% compression: **17.53M bytes** ← DOES NOT FIT
- At 50% compression: **15.94M bytes** ← barely fits
- BigramHash(10240) is ONLY feasible with very aggressive WD + excellent compression

**With BigramHash(4096, 512) embeddings:**
- 4096 * 512 = 2,097,152 extra params → ~2.11M bytes raw
- Total raw: ~28.72M bytes
- At 55% compression: **15.80M bytes** ← fits with ~120K headroom
- At 60% compression: **17.23M bytes** ← DOES NOT FIT

**Budget conclusion:**
- 11L/3xMLP with mixed int5/int6 + zstd-22 fits at ≤60% compression. Tight.
- BigramHash(4096) is feasible at ≤55% compression. Very tight.
- BigramHash(10240) likely requires ≤50% compression — only with aggressive WD (0.04).
- Weight decay is not just a training regularizer — it's a byte budget enabler.
- 12L is possible with gradient-guided quant (PR #332) but pushes budget even harder.
- **Must measure actual artifact size early — don't assume compression ratio.**

---

## 2. Dependency Graph

```
                    ┌─────────────────────┐
                    │  int6/int5 + zstd    │
                    │  (unlocks budget)    │
                    └──────┬──────────────┘
                           │
              ┌────────────┼────────────────┐
              ▼            ▼                 ▼
        ┌──────────┐ ┌──────────┐    ┌──────────────┐
        │ 11 layers │ │ 3x MLP   │    │ BigramHash   │
        └────┬─────┘ └──────────┘    │ (needs bytes) │
             │                        └──────────────┘
             ▼
    ┌────────────────┐
    │ XSA on last 4  │  (works on any layer count, but which 4 depends on total)
    └────────────────┘

    ┌──────────────────────────────────────────────────────┐
    │ Independent (no dependencies):                        │
    │  - SmearGate                                          │
    │  - Orthogonal init                                    │
    │  - Partial RoPE + LN Scale                           │
    │  - Weight decay 0.02-0.04                            │
    │  - SWA/EMA during warmdown                           │
    │  - Sliding window eval (stride=64)                   │
    │  - Turbo-Muon (4 NS steps)                           │
    │  - DDP bucket tuning + static_graph                  │
    │  - Packed QKV                                         │
    └──────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────┐
    │ Depends on having a good base model:                  │
    │  - QAT (start at 85% wallclock, needs trained model)  │
    │  - TTT at eval (needs quantized artifact)             │
    │  - PPM-C eval mixer (additive, at eval time)          │
    └──────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────┐
    │ SWA + QAT interaction:                                │
    │  SWA can reverse quant gap (post-SWA int6 BPB <       │
    │  pre-quant BPB) — #238. So SWA should run BEFORE      │
    │  quantization. QAT should start at 85% wallclock,     │
    │  SWA/EMA at warmdown start.                           │
    └──────────────────────────────────────────────────────┘
```

---

## 3. The Competitive Stack (Phase 1 — Architecture + Training)

These are the techniques every top-10 entry uses. This is not research — this is
catching up to the field.

### 3A. Quantization: int5/int6 + zstd-22

**What to change in `train_gpt.py`:**

```python
# Replace zlib with zstd (line ~1340):
# OLD: quant_blob = zlib.compress(quant_raw, level=9)
# NEW:
import zstandard as zstd
compressor = zstd.ZstdCompressor(level=22)
quant_blob = compressor.compress(quant_raw)

# In quantize_float_tensor, add int6 path:
def quantize_float_tensor(t, bits=8):
    max_val = (1 << (bits - 1)) - 1  # 127 for int8, 31 for int6, 15 for int5
    # ... clip to max_val, scale by max_val instead of 127
```

**Mixed quant:** int5 for MLP weights (fc, proj in MLP), int6 for attention weights
(c_q, c_k, c_v, proj in attn), int8 for tok_emb. Dispatch by parameter name pattern.

**QAT (late):** Add STE (Straight-Through Estimator) starting at 85% of wallclock.
During forward pass, fake-quantize weights: `w_q = dequant(quant(w))`, use `w_q` for
compute but backprop through `w` via straight-through. Costs ~8% throughput (#360).

**Add `zstandard` to requirements.txt.**

### 3B. Model size: 11 layers, 3x MLP

```python
# Environment variables:
NUM_LAYERS=11  MLP_MULT=3
```

No code change needed — these are already env-var-configurable. The only consequence
is skip_weights shape changes (encoder=5, decoder=6, skips=5).

### 3C. XSA (Exclusive Self Attention) on last 4 layers

From XSA paper (2603.09078). Two lines of actual math.

**Concrete code change in `CausalSelfAttention.forward()`:**

```python
# After y = F.scaled_dot_product_attention(...) or flash_attn_3_func(...)
# and before return self.proj(y):

if self.use_xsa:
    # v has shape (B, S, num_kv_heads, head_dim) — expand to match q heads
    v_expanded = v.repeat_interleave(self.num_heads // self.num_kv_heads, dim=2)
    # For SDPA path, v_expanded needs (B, num_heads, S, head_dim) then back
    # y is (B, S, dim) at this point after reshape
    v_flat = v_expanded.reshape(bsz, seqlen, -1)  # (B, S, dim)
    # Remove self-value projection: z = y - (y·v̂)v̂
    v_norm = F.normalize(v_flat, dim=-1)
    y_proj = (y * v_norm).sum(dim=-1, keepdim=True)
    y = y - y_proj * v_norm
```

**Need to add to `__init__`:** `self.use_xsa = use_xsa` parameter.
**Need to pass to Block/GPT:** `XSA_LAYERS` env var, apply to last N layers.

**Confirmed by:** All top-5 scored entries (#374, #315, #338, #287, #332) use XSA4.

### 3D. Orthogonal Init

Replace Kaiming init for Q, K, V, and MLP fc/proj with orthogonal init.

```python
# In GPT._init_weights():
for module in self.modules():
    if isinstance(module, CastedLinear):
        if getattr(module, '_zero_init', False):
            nn.init.zeros_(module.weight)
        else:
            nn.init.orthogonal_(module.weight)
```

**Confirmed by:** Leaderboard #2 (Raahil Shah, 1.1458), PR #135 (1.1539), #164 (1.1524).

### 3E. Weight Decay on Muon: 0.02-0.04

Currently Muon has no weight decay. Add it.

```python
# In Muon.step(), after applying the update:
for p in params:
    g = updates_flat[curr : curr + p.numel()].view_as(p).to(dtype=p.dtype)
    p.add_(g, alpha=-lr)
    if weight_decay > 0:
        p.add_(p, alpha=-lr * weight_decay)
    curr += p.numel()
```

Add `MUON_WEIGHT_DECAY` env var (default 0.04). Competition consensus: 0.02-0.04.
"Weight decay controls artifact size: aggressive WD reduces quant gap AND compressed size
(#98)" — this helps both bpb and byte budget.

### 3F. Partial RoPE + LN Scale

**Partial RoPE:** Apply RoPE to only a fraction of head dimensions. The rest stay position-free.

```python
# In CausalSelfAttention.__init__:
self.rope_dims = int(self.head_dim * rope_fraction)  # e.g., 0.5 → 32 dims
self.rotary = Rotary(self.rope_dims, base=rope_base)

# In forward, apply RoPE only to first rope_dims of q and k:
q_rope, q_pass = q[..., :self.rope_dims], q[..., self.rope_dims:]
k_rope, k_pass = k[..., :self.rope_dims], k[..., self.rope_dims:]
q_rope = apply_rotary_emb(q_rope, cos, sin)
k_rope = apply_rotary_emb(k_rope, cos, sin)
q = torch.cat([q_rope, q_pass], dim=-1)
k = torch.cat([k_rope, k_pass], dim=-1)
```

**LN Scale:** Learned per-head temperature scaling after QK dot product. Adds
`head_scale = nn.Parameter(torch.ones(num_heads))` and multiplies attention logits.
Small tensor, negligible byte cost.

**Confirmed by:** #374 (1.1246), #315 (1.1248), #332 (1.1320).

### 3G. BigramHash Embeddings

Hash consecutive token pairs into auxiliary embedding buckets, sum with token embedding.

```python
class BigramHash(nn.Module):
    def __init__(self, num_buckets: int, dim: int):
        super().__init__()
        self.emb = nn.Embedding(num_buckets, dim)
        self.num_buckets = num_buckets

    def forward(self, x: Tensor) -> Tensor:
        # x: (B, T) token ids
        prev = F.pad(x[:, :-1], (1, 0), value=0)  # shift right, pad with 0
        bigram_hash = (prev * 1000003 + x) % self.num_buckets
        return self.emb(bigram_hash)

# In GPT.forward():
x = self.tok_emb(input_ids) + self.bigram_hash(input_ids)
```

Bucket count: 4096 is the safe default (fits at 55% compression). 10240 is only
feasible with very aggressive weight decay (0.04) achieving ≤50% compression — the
leaderboard #1 (thwu1) used 10240 + WD=0.04 and presumably achieved this. Start with
4096 and increase only after measuring actual artifact size.
**Confirmed by:** Leaderboard #1 (thwu1, 10240 buckets), #2 (Raahil Shah).

### 3H. SmearGate

Learned static sigmoid gate for local context mixing.

```python
# In Block.__init__:
self.smear_gate = nn.Parameter(torch.zeros(dim))  # sigmoid(0) = 0.5

# In Block.forward, before or after attention:
gate = torch.sigmoid(self.smear_gate.to(x.dtype))[None, None, :]
x_shifted = F.pad(x[:, :-1], (0, 0, 1, 0))  # shift by 1 position
x = gate * x + (1 - gate) * x_shifted
```

Static gate (learned parameter, not input-dependent) beats content-dependent (#288: 1.6795).
**Confirmed by:** Leaderboard #2, #4, and dozens of entries.

### 3I. SWA / EMA During Warmdown

**Tight SWA** (from #374, the SOTA): average checkpoints from last ~600 steps,
every 50 steps, scale < 0.2.

```python
# After each training step during warmdown:
if step >= warmdown_start and step % 50 == 0:
    if swa_model is None:
        swa_model = copy.deepcopy(base_model.state_dict())
        swa_count = 1
    else:
        for k in swa_model:
            swa_model[k] = swa_model[k] + (base_model.state_dict()[k] - swa_model[k]) / (swa_count + 1)
        swa_count += 1

# Before final eval, load swa_model weights
```

**EMA alternative** (momentum=0.997): `ema[k] = 0.997 * ema[k] + 0.003 * model[k]`
every step during warmdown. Costs ~32% of steps in throughput (#360) because it doubles
memory traffic. SWA is cheaper (only snapshots every 50 steps).

**Recommendation:** Start with SWA (cheaper). Switch to EMA only if SWA doesn't work.

### 3J. Sliding Window Eval (stride=64)

```python
# In eval_val(), modify the token iteration to use overlapping windows:
stride = 64  # tokens
for start in range(0, total_tokens - seq_len, stride):
    x = val_tokens[start : start + seq_len]
    y = val_tokens[start + 1 : start + seq_len + 1]
    # Only count loss for the last `stride` tokens (the new ones)
    loss = model(x, y)  # need to modify to return per-token losses
    # Accumulate only tokens[seq_len - stride : seq_len]
```

This requires modifying `eval_val` to support per-token loss accumulation and only
counting tokens that haven't been evaluated before.

**Confirmed by:** Every top-10 entry uses stride=64. Leaderboard #8 (Matthew Li, 1.1925)
was the first to add it and jumped from 1.2244 baseline.

### 3K. Muon Momentum 0.99

"Muon momentum 0.99 is consensus optimal" (tracker). Current default is 0.95.

```python
MUON_MOMENTUM=0.99
```

One env var change. #5 on confirmed leaderboard (yahya010) explicitly uses 0.99.

---

## 4. Systems Throughput Improvements (Phase 2)

Per the consolidated notes: "the competition is now throughput-limited, not
technique-limited" (PR #369). On 8xH100, FA3 gives 58ms/step vs 99ms/step with SDPA —
71% more training steps.

### 4A. DDP Bucket Tuning + static_graph

```python
# Line 1027-1029, change DDP constructor:
DDP(compiled_model, device_ids=[local_rank], broadcast_buffers=False,
    static_graph=True, gradient_as_bucket_view=True, bucket_cap_mb=1)
```

**Why bucket_cap_mb=1:** Our model is ~17M params * 4 bytes = ~68MB of gradients.
Default bucket_cap_mb=25 means 3 buckets. With bucket_cap_mb=1, we get ~68 buckets,
allowing DDP to start allreducing early layers while later layers still compute backward.

**Risk:** Low. One-line change. `static_graph=True` may break if model structure is
dynamic (it isn't — our model has fixed shapes).

### 4B. Turbo-Muon (4 Newton-Schulz steps)

Paper 2512.04632 claims 2.8x NS speedup, 5-10% end-to-end. We currently do 5 NS steps.

```python
# In zeropower_via_newtonschulz5, add preconditioning:
def zeropower_via_newtonschulz(G, steps=4, eps=1e-7):
    a, b, c = (3.4445, -4.7750, 2.0315)
    X = G.bfloat16()
    # Preconditioning step (from Turbo-Muon):
    X /= X.norm() + eps
    # ... rest same but with steps=4
```

Need to read their actual code for the preconditioning formula. The change is localized
to `zeropower_via_newtonschulz5`.

### 4C. Packed QKV

Merge c_q, c_k, c_v into one matmul:

```python
# In CausalSelfAttention.__init__:
qkv_dim = dim + 2 * kv_dim  # 512 + 256 + 256 = 1024
self.c_qkv = CastedLinear(dim, qkv_dim, bias=False)

# In forward:
qkv = self.c_qkv(x)
q, k, v = qkv.split([dim, kv_dim, kv_dim], dim=-1)
```

One larger matmul instead of three smaller ones. Saves kernel launch overhead.

### 4D. Persistent Muon Buffer

```python
# In Muon.__init__:
self._updates_flat = None
self._total_params = None

# In Muon.step():
if self._updates_flat is None or self._total_params != total_params:
    self._updates_flat = torch.zeros(total_params, device=..., dtype=torch.bfloat16)
    self._total_params = total_params
else:
    self._updates_flat.zero_()
```

Avoids per-step allocation of a ~17M-element bf16 tensor.

### 4E. Verify softcap+CE Fusion

Before writing a custom Triton kernel, check if torch.compile already fuses it:

```bash
TORCH_LOGS="+output_code" torchrun --nproc_per_node=1 train_gpt.py 2>&1 | grep -A5 "tanh"
```

If the compiled graph materializes the softcapped logits tensor separately from CE,
then a fused kernel is worth writing. If compile already fuses them, skip this.

Our logit tensor is small: `[B*T, 1024]` = `[512*1024, 1024]` ≈ 1M elements ≈ 2MB in
bf16. At dim=512, this is not the dominant cost. But it's a free check.

---

## 5. Eval-Time Improvements (Phase 3)

### 5A. TTT (Test-Time Training)

From Dynamic Evaluation paper (2403.01518) and competition entries:

**Start simple (Dynamic Evaluation style):**
1. After loading the quantized model, before eval
2. Run SGD on each sliding window of validation data
3. Update only MLP params (confirmed by both papers and competition)
4. LR: sweep 1e-6 to 3e-5 (Dynamic Eval paper)
5. Use the streaming/Transformer-XL style (process each token once, keep KV cache)

**Competition variant (LoRA TTT):**
- Add LoRA adapters (rank 4-16) to MLP layers at eval time
- Train only the LoRA params
- Smaller memory footprint, faster gradient computation
- PR #338 (alertcat) combined TTT + XSA + EMA for 1.1254

**Key constraints:**
- "Test-time training only on already-evaluated tokens" — causal, no lookahead
- "Eval also < 10 min separately" — limits how many TTT steps we can do
- TTT after int8 roundtrip: the dequantized weights may not be ideal for fine-tuning
  (quantization noise in the starting point)

**Which layers to update:** Dynamic Eval paper (Appendix D) finds middle layers are best
for single-layer adaptation. TTT-E2E paper finds last 1/4 of blocks. Competition uses
last 2-3 layers. For our 11L model, try layers 8-10.

### 5B. PPM-C Eval-Time Context Mixer

PR #283 claims ~0.015 BPB improvement at zero artifact cost. This is a pure eval-time
post-processing step that mixes neural LM probabilities with n-gram statistics.

Low priority — small gain, but zero cost to artifact size. Implement after everything
else is working.

---

## 6. Optimizer Improvements (Phase 4)

### 6A. Mousse (if needed)

Paper 2603.09697. Only consider if we've exhausted Phase 1-3 and need an edge.

**Key hyperparameters from the paper:**
- `beta_pc = 0.95` (curvature EMA decay)
- `alpha = 0.125` (spectral tempering exponent, vs standard 0.25)
- `epsilon = 1e-6` (regularization for eigenvalues)
- `T = 10` (eigendecomposition frequency)
- Single-sided (L-only) variant recommended for our scale

**Risk:** Their smallest experiment is 160M. Our model is 18-26M. Benefits may not
transfer. The eigendecomposition every 10 steps is for max 512x512 and 1536x1536
matrices — small enough to be fast, but may not compile cleanly.

---

## 7. MLX Smoke-Test Strategy

`train_gpt_mlx.py` is a faithful 1:1 port of the CUDA architecture. Use it to prototype
architectural changes locally before burning H100 time.

**What CAN be tested on MLX:**
- XSA implementation correctness (2 lines of code, check loss doesn't diverge)
- BigramHash + SmearGate (architecture changes, check they don't break training)
- Orthogonal init (just change init, run 200 steps, check loss trajectory)
- Partial RoPE (modify the Rotary module, check training doesn't diverge)
- LN Scale (add per-head temperature, quick convergence check)
- 11L / 3x MLP (just env vars: `NUM_LAYERS=11 MLP_MULT=3`)

**What CANNOT be tested on MLX:**
- Throughput measurements (unified memory, no PCIe, no DDP)
- DDP tuning
- CUDA Graph / torch.compile mode experiments
- FA3
- Actual bpb numbers (MLX warmup doesn't restore state, so numbers differ slightly)

**MLX smoke test protocol:**
```bash
# Download minimal data:
python3 data/cached_challenge_fineweb.py --variant sp1024 --train-shards 1

# Baseline (should complete in ~2 min on M-series):
RUN_ID=baseline ITERATIONS=200 TRAIN_BATCH_TOKENS=8192 VAL_LOSS_EVERY=0 \
  VAL_BATCH_SIZE=8192 python3 train_gpt_mlx.py

# With changes (example: 11L + 3x MLP + XSA):
RUN_ID=test_xsa ITERATIONS=200 TRAIN_BATCH_TOKENS=8192 VAL_LOSS_EVERY=0 \
  VAL_BATCH_SIZE=8192 NUM_LAYERS=11 MLP_MULT=3 python3 train_gpt_mlx.py
```

**Key MLX gotcha:** Warmup does NOT restore model state (unlike CUDA). This means
model starts from a slightly mutated initialization. Compare MLX runs only to other MLX
runs, not to CUDA numbers.

---

## 8. Execution Phases

### Phase 1A: Foundation (MLX prototyping, ~1 day)

Test all architectural changes on MLX locally:

1. Orthogonal init (one line change)
2. 11L / 3x MLP (env vars only)
3. XSA on last 4 layers
4. BigramHash (4096 buckets)
5. SmearGate (static gate)
6. Partial RoPE (0.5 fraction)
7. Weight decay 0.04 on Muon
8. Muon momentum 0.99

Run 200-step smoke tests for each. Verify nothing diverges. Then run a 200-step test
with all changes combined. Compare final train loss to baseline.

### Phase 1B: Quantization + Compression (~0.5 days)

1. Implement int6 per-row quantization
2. Implement int5 per-row quantization
3. Switch to zstd-22
4. Verify artifact size fits in 16MB with 11L/3xMLP + BigramHash(4096)
5. Implement late QAT (STE at 85% wallclock)

### Phase 1C: Scored 1xH100 Run (~0.5 days)

Deploy the full Phase 1 stack on 1xH100:
```bash
RUN_ID=phase1_1xh100 \
  NUM_LAYERS=11 MLP_MULT=3 \
  MUON_MOMENTUM=0.99 MUON_WEIGHT_DECAY=0.04 \
  ATTENTION_IMPL=fa3 FUSE_BATCH_TRANSFER=1 \
  MAX_WALLCLOCK_SECONDS=600 VAL_LOSS_EVERY=0 \
  torchrun --standalone --nproc_per_node=1 train_gpt.py
```

Expected: val_bpb in the 1.14-1.16 range on 1xH100 (limited by throughput).

### Phase 2: Systems Throughput (~1 day)

1. DDP bucket_cap_mb=1 + static_graph + gradient_as_bucket_view (trivial)
2. Turbo-Muon (read their code, implement, benchmark)
3. Packed QKV (merge 3 linears into 1)
4. Persistent Muon buffer

Benchmark each on 1xH100 for tok/s. Then run combined on 8xH100.

### Phase 3: Eval Stack (~1 day)

1. Sliding window eval (stride=64)
2. SWA during warmdown (every 50 steps, last 600 steps)
3. If time: simple TTT (SGD on MLP params, LR=1e-5)
4. If time: PPM-C context mixer

### Phase 4: 8xH100 Final Submission

Combine all working changes. Three scored runs for statistical significance.
Target: val_bpb < 1.13.

---

## 9. Revised Priority Table

| # | Item | Impact type | Estimate | Effort | Risk | Depends on |
|--:|------|-------------|----------|--------|------|------------|
| 1 | int5/int6 + zstd-22 | Unlocks budget | Required | Medium | Low | Nothing |
| 2 | 11L + 3xMLP | bpb | ~-0.03 | Trivial | Low | #1 |
| 3 | XSA on last 4 layers | bpb | ~-0.01 | Low | Low | Nothing |
| 4 | Sliding window eval stride=64 | bpb | ~-0.01 | Low | Low | Nothing |
| 5 | Orthogonal init | bpb | ~-0.005 | Trivial | Low | Nothing |
| 6 | Weight decay 0.04 on Muon | bpb + quant | ~-0.005 | Trivial | Low | Nothing |
| 7 | Muon momentum 0.99 | bpb | ~-0.003 | Trivial | Low | Nothing |
| 8 | BigramHash (4096 buckets) | bpb | ~-0.005 | Low | Low | #1 (bytes) |
| 9 | SmearGate (static) | bpb | ~-0.003 | Low | Low | Nothing |
| 10 | SWA tight (last 600 steps) | bpb + quant | ~-0.005 | Low | Low | Nothing |
| 11 | Partial RoPE (0.5) + LN Scale | bpb | ~-0.005 | Low | Low | Nothing |
| 12 | Late QAT (85% wallclock) | quant gap | ~-0.005 | Medium | Medium | #1 |
| 13 | DDP bucket_cap_mb=1 + static_graph | tok/s on 8x | +1-3% | Trivial | Low | Nothing |
| 14 | Turbo-Muon (4 NS steps) | tok/s | +3-8% | Low | Low | Nothing |
| 15 | Packed QKV | tok/s | +2-5% | Low | Low | Nothing |
| 16 | Persistent Muon buffer | tok/s | +1-4% | Low | Low | Nothing |
| 17 | Verify softcap+CE fusion | tok/s | +0-3% | Trivial | None | Nothing |
| 18 | TTT at eval time | bpb | ~-0.01-0.03 | High | Medium | Working stack |
| 19 | PPM-C eval mixer | bpb | ~-0.015 | Medium | Low | Working stack |
| 20 | Mousse optimizer | bpb | ~-0.005-0.015 | High | Medium | Nothing |

**Stacking estimate (speculative, not repo-measured):**
- Baseline: ~1.2244
- +int6/11L/3xMLP: ~1.19 (leaderboard #3 got 1.1502 with this)
- +XSA4: ~1.18
- +BigramHash+SmearGate: ~1.17
- +OrthoInit+WD+PartialRoPE+LNScale: ~1.16
- +SWA+QAT: ~1.15
- +Sliding eval: ~1.14
- +Throughput gains (more steps in 10min): ~1.13
- +TTT: ~1.12

This is the path to ~1.12, which would be competitive with current SOTA (1.1246).
Every number above is speculative. The only way to know is to measure.

---

## 10. Paper Reference Index

| ID | Title | Area | Status | Actionable? |
|---|---|---|---|---|
| 2512.04632 | Turbo-Muon | Optimizer speed | Abstract | Yes — drop-in NS replacement |
| 2603.09697 | Mousse | Optimizer quality | Full read | Maybe — scale risk |
| 2603.09078 | XSA | Architecture | Full read | **Yes — top priority** |
| 2410.19456 | SLM Bottlenecks | Systems | Full read | Background — validates our findings |
| 2501.12084 | Hopper Microbenchmarks | Hardware | Abstract | Background — H2D understanding |
| 2512.23675 | TTT-E2E | Eval-time | Full read | Yes — Phase 3 |
| 2403.01518 | Dynamic Evaluation | Eval-time | Full read | Yes — Phase 3, simpler start |
| 2502.01637 | SCONE | N-gram embeddings | Abstract | Background — supports BigramHash |
| 2512.04746 | SignRoundV2 | Quantization | Abstract | Maybe — gradient-guided quant |
| 2509.20214 | Q-Palette | Quantization | Abstract | Maybe — optimal bit allocation |
| 2106.04426 | Hash Layers | Hash embeddings | Abstract | Background — supports BigramHash |
| 2410.10989 | Liger Kernel | Fused kernels | Abstract | Maybe — if compile doesn't fuse |
| 2503.19779 | PyGraph | CUDA Graphs | Abstract | Low priority — current compile works |
| 2509.16248 | GraphMend | torch.compile | Abstract | Low priority — fullgraph works |
| 2502.15015 | AlgoPerf | Competition analysis | Abstract | Background — compile insights |
| 2504.09844 | MegaScale-Data | Data loading | Abstract | Background — validates prefetch |
| 2501.01005 | FlashInfer | Attention kernels | Abstract | Not actionable — inference only |

---

## 11. Negative Results to Avoid (from competition)

| Technique | Result | Source |
|---|---|---|
| Content-dependent SmearGate | Much worse than static (1.68 vs ~1.15) | PR #288 |
| Error-guided TTT | Doesn't work — high-loss tokens are unpredictable | PR #296 |
| int5 on undertrained models | Catastrophic | PR #238 |
| QAT at int8 level | Overhead exceeds recovery | PR #145 |
| Width > depth (4x768 vs 9x512) | 1.3043 vs 1.2244 — depth wins | PR #185 |
| SWA with int8 + default warmdown | No benefit | PR #199 |
| BitNet ternary | Dead end — entire stack breaks | PR #367 |
| 4x MLP | 1.4444 — too aggressive | PR #228 |
| Depth recurrence (3 cycles) | 900x quant error amplification | PR #363 |
| `TORCH_COMPILE_MODE=reduce-overhead` | Crashes | Our systems testing |
| `TORCH_COMPILE_MODE=max-autotune` | Crashes | Our systems testing |
| `PIN_SHARD_MEMORY=1` | Noise (0.0%) | Our systems testing |
| `SDPA_BACKEND=cudnn` | Slightly worse (-1%) | Our systems testing |
| `FUSE_BATCH_TRANSFER=1` on Hyperbolic H100 | Noise (0.01%) | `notes/journal/2026-03-22-hyperbolic-1xh100.md` |

---

## 12. Hyperbolic H100 Negative Result — Platform Sensitivity

**Critical finding from `notes/journal/2026-03-22-hyperbolic-1xh100.md`:**

The `FUSE_BATCH_TRANSFER=1` optimization that showed -36% step time on RunPod 1xH100
showed **0.01% (noise)** on Hyperbolic 1xH100 SXM5. Same GPU class, completely
different result.

| Provider | GPU | `FUSE_BATCH_TRANSFER` delta | `step_avg` |
|---|---|---|---|
| RunPod | 1xH100 SXM | **-36%** step time | 332ms vs 520ms |
| Hyperbolic | 1xH100 SXM5 | **-0.01%** (noise) | 333.16ms vs 333.20ms |
| AWS | 1xL40S | **-0.9%** | ~1003ms vs 1012ms |

**Interpretation:**
- The RunPod result is now **provider/platform-specific**, not a universal H100 win.
- The Hyperbolic baseline is already ~333ms/step — almost identical to the RunPod
  FUSED result. This suggests the Hyperbolic box's driver/runtime was already handling
  the two-.to() path efficiently, or torch.compile was generating different code.
- Possible explanations: different CUDA driver version, different PyTorch build,
  different PCIe configuration, different CPU, or different torch.compile behavior
  between torch 2.10.0+cu128 (Hyperbolic) and whatever was on RunPod.
- `flash-attn` was NOT installed on Hyperbolic, so FA3 was not tested.

**Impact on the plan:**
- Systems throughput gains (Phase 2) are less certain than previously estimated.
- The "5-15% cumulative systems gains" from the consolidated notes should be treated
  as optimistic until reproduced on the actual submission hardware (RunPod H100 SXM).
- The focus should be **even more heavily on modeling/architecture changes** (Phase 1),
  which are hardware-independent.
- Still do systems work, but don't count on it for bpb — count on it for tok/s only
  if measured on the actual target hardware.

---

## 13. Triton / CUDA C++ Kernel Analysis — Will They Help?

### Operation Profile at dim=512

Full per-operation analysis of one training step on 8xH100 (B=64, S=1024, D=512):

**Total step FLOP: ~9.1 TFLOP** (2.85T forward + 6.03T backward + 0.21T Muon)

| Category | FLOP | % of total | Bound | Kernel optimization potential |
|---|---|---|---|---|
| MLP matmuls (fc_up + proj_down, fwd+bwd) | 3,710G | 41% | Compute | None — cuBLAS is optimal for [65536,512]@[512,1024] |
| SDPA (fwd + bwd) | 2,165G | 24% | Compute | FA3 is already optimal; no custom kernel beats it |
| QKV + output proj matmuls (fwd+bwd) | 2,782G | 31% | Compute | cuBLAS is optimal; packed QKV helps launch overhead |
| LM head matmul (fwd+bwd) | 206G | 2% | Compute | cuBLAS optimal |
| Newton-Schulz matmuls | 208G | 2% | Compute | Small matrices (512x512), Turbo-Muon helps |
| Elementwise + norms + RoPE | ~20G | <1% | **Memory** | **THIS is where kernels help** |

### Where custom kernels CAN help (memory-bound operations)

The memory-bound operations are ~<1% of total FLOP but they still consume wall time
because they're limited by HBM bandwidth (3.35 TB/s on H100), and each one is a
separate kernel launch. The wins from fusing them are:

1. **Reduced kernel launch overhead:** Each unfused kernel launch costs ~5-10us on H100.
   With ~160+ memory-bound kernels per step (norms, RoPE, scales, residuals, relu^2,
   softcap, CE), that's ~0.8-1.6ms of pure launch overhead. At 333ms step time, this
   is 0.2-0.5%.

2. **Reduced HBM traffic:** If torch.compile already fuses adjacent elementwise ops
   (e.g., relu+square, softcap+CE), custom kernels add nothing. If it doesn't, the
   unfused version reads/writes the intermediate tensor twice.

### torch.compile already handles most of this

`torch.compile(model, dynamic=False, fullgraph=True)` with Inductor backend:
- **Does fuse:** relu+square, scale+add residuals, adjacent elementwise ops, norm+scale
- **Likely fuses:** softcap (tanh) + CE into a single reduction kernel
- **Cannot fuse:** matmuls with elementwise ops (matmul boundaries are kernel boundaries)
- **Cannot fuse:** operations across the forward/backward boundary

### What a custom Triton kernel COULD fuse that torch.compile might not:

1. **Fused RMSNorm + Linear (forward):**
   Compute `F.rms_norm(x, (D,))` then immediately `F.linear(x, W)` without writing
   the normalized x back to HBM.
   - Saves: one `[65536, 512]` write+read = 134MB per occurrence
   - Occurrences: 2 per layer (attn_norm→c_q, mlp_norm→fc) × 9 layers = 18
   - Total saved traffic: 18 × 134MB = 2.4GB
   - At 3.35 TB/s: saves ~0.72ms
   - **At 333ms step time: ~0.2% improvement**
   - **Verdict: Not worth the effort** for 0.2%.

2. **Fused softcap + CE (forward):**
   Compute `30*tanh(logits/30)` and `cross_entropy` in one kernel, avoiding materializing
   the softcapped logits tensor.
   - The softcapped tensor is [65536, 1024] in float32 = 268MB
   - Saves one write+read = 536MB
   - At 3.35 TB/s: saves ~0.16ms
   - **At 333ms step time: ~0.05% improvement**
   - **Verdict: Not worth it.** torch.compile likely already fuses this.

3. **Fused relu^2 MLP (forward):**
   Compute `relu(fc(x))^2` in one kernel without materializing the relu output.
   - Saves: [65536, 1024] intermediate = 134MB write+read = 268MB
   - Per layer: 268MB saved × 9 layers = 2.4GB
   - At 3.35 TB/s: ~0.72ms saved
   - **~0.2% improvement**
   - **Verdict: Not worth it.** torch.compile almost certainly fuses relu+square.

4. **Fused QK RMSNorm + RoPE + Gain:**
   After QKV projection, fuse the RMSNorm(q), RMSNorm(k), RoPE application, and
   q_gain scaling into one kernel that reads q,k once and writes the ready-for-SDPA
   q,k once.
   - Currently: 4 separate memory-bound ops on Q, 3 on K
   - Saves: ~6 intermediate tensor writes+reads
   - Q intermediates: 6 × [64,8,1024,64] × 2 bytes = 6 × 67MB = 402MB
   - K intermediates: 4 × [64,4,1024,64] × 2 bytes = 4 × 33.5MB = 134MB
   - Total saved per layer: ~536MB × 9 layers = 4.8GB
   - At 3.35 TB/s: ~1.4ms
   - **At 333ms step time: ~0.4% improvement**
   - **Verdict: Marginal.** Only worth doing if torch.compile doesn't already fuse these.

### What a CUDA C++ kernel could do that Triton can't:

Triton operates at the block/tile level and generates PTX. For our model dimensions:
- Matrix tiles at dim=512 are well-served by Triton's defaults
- CUDA C++ (CUTLASS, etc.) could theoretically achieve better warp scheduling for
  the small Newton-Schulz matmuls (512×512), but this is where torch.compile already
  wraps the function

**Verdict on CUDA C++:** Not worth it. The only compute-bound operations that custom
CUDA C++ could improve are the Newton-Schulz matmuls (2% of step FLOP), and Turbo-Muon
(a Python-level change to reduce iterations from 5→4) is a better investment.

### The real answer: kernel work is a bad investment at this model size

**Summary of all custom kernel opportunities:**

| Fusion | Saved traffic | Saved time | % of step |
|---|---|---|---|
| RMSNorm + Linear | 2.4GB | 0.72ms | 0.2% |
| softcap + CE | 0.54GB | 0.16ms | 0.05% |
| relu^2 fusion | 2.4GB | 0.72ms | 0.2% |
| QK norm+RoPE+gain | 4.8GB | 1.4ms | 0.4% |
| **All combined** | **10.1GB** | **3.0ms** | **0.9%** |

Even if you wrote perfect Triton kernels for ALL of these AND torch.compile isn't
already doing any of it, the total win is ~0.9% of step time. In practice,
torch.compile handles most of these fusions already, so the real gain is likely
0.0-0.3%.

**Compare to:**
- XSA: ~0.01-0.02 bpb improvement (modeling change, 2 lines of code)
- int6+zstd: unlocks 11L/3xMLP (~0.03 bpb)
- Sliding window eval: ~0.01 bpb (pure eval change)

The competition is won on modeling and quantization, not on custom kernels at dim=512.
Custom kernels become important when dim > 2048 and the elementwise ops consume a
larger fraction of step time.

### When kernel work IS worth it

1. **If torch.compile is not fusing relu+square:** Verify with profiling first. If it's
   launching separate relu and square kernels, file a torch.compile bug or write a
   2-line Triton kernel. But verify first.

2. **If we move to 3xMLP (hidden=1536):** The MLP intermediates grow by 50%, making
   MLP-related fusions slightly more impactful. Still <1% total.

3. **For the Liger FusedLinearCrossEntropy:** This fuses the lm_head matmul WITH softcap
   WITH CE, avoiding materializing the logit tensor entirely. But our logit tensor is
   only [65536, 1024] = 268MB (float32). The matmul itself (68.72G FLOP) runs in ~17us
   on H100. The savings from not materializing the intermediate are ~0.16ms. Not worth
   the integration cost.

4. **Packed QKV:** This is NOT a kernel fusion — it's replacing 3 cuBLAS calls with 1.
   The kernel launch overhead saving (~10-20us) is real but small. The main win is
   reducing the number of backward matmuls. Worth doing for ~2-5% throughput gain from
    reduced launch overhead across the whole step.

---

## 14. Systems-Only Findings from Competition Tracker

These are observations from `tracker.md` that specifically affect GPU throughput or
kernel-level efficiency — not training hyperparameters, not model architecture.

### 14A. PR #376 — Custom Kernel Pipeline (1.1401 with 9L)

PR #376 (anthony-maio) achieved **1.1401 with only 9 layers** using "Custom Kernel
Pipeline." This is one of only two entries that explicitly does systems-level work and
it's competitive with many 11L entries.

**Why this matters for our kernel analysis:** Our Section 13 concluded custom kernels
are worth ~0.9% max. But if anthony-maio's "custom kernel pipeline" helped them fit
more effective training into the 10-min window, the actual impact could be larger than
our static FLOP analysis suggests. Kernel launch overhead reduction compounds with
more steps — a 5% throughput gain means 5% more gradient updates, which at the margin
of competition (~0.002 bpb per rank) could be meaningful.

**Action:** Read PR #376's actual code to understand what "Custom Kernel Pipeline"
means. If it's packed QKV + fused norms + fused MLP, that's consistent with our
analysis. If it's something novel, worth understanding.

### 14B. EMA Throughput Cost is 32% (PR #360)

PR #360 (MultiFe22): "QAT costs 8% of steps, EMA costs 32% of steps." EMA requires
maintaining a shadow copy of all weights and updating it every step — this doubles
memory traffic for the weight update portion.

**Systems implication:** If we implement SWA (snapshot every 50 steps) instead of EMA,
the throughput cost drops to near-zero. This data point is relevant when choosing
between SWA and EMA from a pure tok/s perspective.

---

## 15. Modded-NanoGPT Evidence — Revises Our Kernel Analysis

`notes/research/modded-nanogpt.md` documents 77 records of the NanoGPT speedrun on the same hardware (8xH100
SXM) with a very similar architecture (dim=768 vs our 512, same Muon, same relu^2 MLP,
same Newton-Schulz). This is the strongest external evidence we have for what systems
optimizations actually work at our scale.

### Section 13 was wrong: kernels matter more than our FLOP analysis predicted

Our Section 13 estimated all custom kernel opportunities at ~0.9% of step time based
on arithmetic intensity analysis. The nanogpt data shows **6.4% of wall time saved
by kernel fusion alone** (10.85 seconds out of ~170s). The gap comes from three things
our FLOP analysis didn't capture:

1. **The fused linear+relu+square kernel fuses the MATMUL with the activation.**
   Our analysis treated matmuls and elementwise ops as separate and said "matmuls are
   cuBLAS-optimal, elementwise ops are <1% of FLOP." But nanogpt's `linear_relu_square`
   kernel computes `relu(x @ W.T)^2` in a single kernel — the matmul output stays in
   registers and gets relu+squared before writing to HBM. This eliminates the
   intermediate tensor write AND the separate kernel launch. Saved 2.8 seconds (1.6%).

2. **Kernel launch overhead compounds.** At ~5-10us per launch with ~160+ kernels per
   step, launch overhead is ~1ms. But on 8xH100 with 58ms steps (nanogpt's endgame),
   that's 1.7%. Our 333ms steps make this less impactful (0.3%), but if we speed up
   via other means, launch overhead becomes a larger fraction.

3. **Communication overhead at small scale is worse than theoretical.** nanogpt found
   that reduce_scatter bandwidth on small matrices is only ~200GB/s vs 450GB/s nominal
   NVLink — communication is 2.25x slower than theoretical peak for small tensors.

### Proven portables from nanogpt to parameter-golf (systems-only)

These are items from nanogpt that are (a) proven on 8xH100, (b) directly applicable
to our architecture, and (c) purely systems changes (no model architecture change).

#### 15A. Fused linear_relu_square Triton kernel

**nanogpt evidence:** Record #59, saved 2.8 seconds (1.6% of wall time).

**What it does:** Single Triton kernel that computes `relu(x @ W1.T)^2` — the forward
pass of our MLP's first half. Uses TMA (TensorDescriptor API, H100-specific) for
zero-copy data movement. Output stays in registers after the matmul, gets relu+squared
before writing to HBM. Backward kernel loads saved pre-activation values and computes
`2 * grad * relu(pre)` in-register.

**Applicability:** Direct port. Our MLP forward is:
```python
x = torch.relu(self.fc(x))      # fc: [T, 512] @ [512, 1024] → [T, 1024]
return self.proj(x.square())     # proj: [T, 1024] @ [1024, 512] → [T, 512]
```
The fused kernel replaces `fc(x)` → `relu` → `square` with one kernel.

**Note from nanogpt PR #197:** "The second linear (proj) is left as its own kernel
because W2 matmul has different dimensions and no activation fusion opportunity."

**Estimated gain for us:** 1-3% of step time. Smaller than nanogpt's 1.6% because
our hidden dim is 1024 (vs 3072), so the intermediate tensor is smaller. But with
3xMLP (hidden=1536), this grows proportionally.

**Effort:** Medium. Need to write/port a Triton kernel with TMA. The nanogpt source
(`triton_kernels.py` lines 430-540) is the template.

#### 15B. XXT/XTX symmetric Muon kernels

**nanogpt evidence:** Record #27, plus used in all subsequent records.

**What it does:** Exploits the symmetry of `A @ A.T` in Newton-Schulz. Only computes
the upper triangle, mirrors to lower triangle. 50% fewer blocks launched vs naive matmul.

**Applicability:** Direct port. Our `zeropower_via_newtonschulz5` computes `A = X @ X.T`
on every NS iteration, for every Muon parameter.

**Plus `ba_plus_cAA` fused kernel:** Computes `beta*A + alpha*(A @ A.T)` in one launch,
eliminating the intermediate `A@A` tensor and a separate pointwise add.

**Estimated gain:** 1-2% of step time. Our NS matrices are smaller (512×512 vs 768×768)
so the per-kernel gain is smaller, but we do 5 iterations × 6 matrices/layer × 9 layers
= 270 matmuls per optimizer step.

**Effort:** Low-Medium. The nanogpt Triton code (`triton_kernels.py` lines 35-410) is
the template. Needs adaptation for our matrix dimensions and tile sizes.

#### 15C. Replace DDP with reduce_scatter sharded optimizer

**nanogpt evidence:** Records #22-24, #36. "Saves 7/8 of gradient communication bandwidth."

**What it does:** Instead of DDP's all_reduce (every GPU gets full gradient), use
reduce_scatter (each GPU gets 1/8 of gradient), update locally, then all_gather the
parameters.

**Applicability:** Our Muon already does something similar (round-robin parameter
assignment + all_reduce). But the Adam parameters and the final parameter sync still
use DDP all_reduce. Replacing DDP entirely with a manual reduce_scatter + all_gather
pattern would save communication for the non-Muon parameters.

**Plus: parameter banking.** nanogpt packs all attention weights into one big matrix
("attn_bank") and all MLP weights into another ("mlp_bank"), then does ONE reduce_scatter
per bank instead of N per-parameter calls. This reduces communication launch overhead.

**Estimated gain:** 5-10% on 8xH100. This is the single largest systems opportunity
for multi-GPU. Much bigger than our current "DDP bucket tuning" item.

**Effort:** High. Requires replacing DDP with a manual communication pattern. The
Muon optimizer already partially does this, but Adam parameters and the training loop
need restructuring.

#### 15D. BF16 cross entropy (remove float32 cast)

**nanogpt evidence:** Record #37. "Doesn't hurt convergence at all."

**What it does:** Our code does `F.cross_entropy(logits.float(), targets)` — casting
the `[65536, 1024]` logit tensor to float32 before CE. nanogpt shows this float32 cast
is unnecessary.

**Applicability:** Direct, one-line change:
```python
# Line 880 of train_gpt.py:
# OLD: return F.cross_entropy(logits.float(), targets, reduction="mean")
# NEW: return F.cross_entropy(logits, targets, reduction="mean")
```

**Estimated gain:** 0.5-1%. Eliminates a 268MB dtype conversion (the logit tensor
goes from 134MB bf16 to 268MB float32). Small but free.

**Effort:** Trivial. One line change. Must verify bpb is unchanged on a scored run.

#### 15E. BF16 weights with mantissa buffer for Muon

**nanogpt evidence:** Record #57. "Without mantissa tracking, bf16 is substantially
detrimental."

**What it does:** Store Muon-managed weights in BF16 (faster matmul, less communication)
but track the lower 16 bits of the FP32 representation in a separate uint16 buffer.
During optimizer update, reconstruct FP32, apply update, split back.

```python
# Reconstruct FP32 from BF16 + mantissa:
p_fp32 = (p.view(uint32) << 16 | mantissa.view(uint32)).view(float32)
# Apply update in FP32
p_fp32.add_(g, alpha=-lr)
# Split back:
p_raw = p_fp32.view(uint32)
p.copy_((p_raw >> 16).view(uint16).view(bfloat16))
mantissa.copy_(p_raw.view(uint16))
```

**Applicability:** Our `CastedLinear` already stores weights in FP32 and casts to BF16
in forward. Switching to BF16 storage + mantissa would:
- Make `F.linear(x, weight)` skip the `.to(x.dtype)` cast (weight already BF16)
- Halve weight communication volume in DDP (2 bytes vs 4 bytes per param)
- Halve weight memory (but add 2 bytes for mantissa — net neutral for Muon params)

The net gain comes from faster matmuls (no in-kernel dtype cast) and cheaper DDP communication.

**Estimated gain:** 3-8% step time (nanogpt data). Mainly from communication savings
on 8xH100.

**Effort:** Medium. Need to add mantissa buffers to Muon, modify CastedLinear to store
BF16 directly, ensure the bit-manipulation is correct.

#### 15F. Async data prefetch with threading

**nanogpt evidence:** Record #33. Uses `threading.Event()` + background thread.

**What it does:** Load next data shard in a background thread while GPU trains. Cast
inputs to int32 on CPU before transfer (avoid dtype conversion during `.to()`).

**Applicability:** Direct port. Our loader is synchronous.

**Estimated gain:** 1-3%. Depends on whether data loading is on the critical path
(it was on RunPod, unclear on Hyperbolic).

**Effort:** Low. Standard Python threading pattern.

#### 15G. Adam every other step

**nanogpt evidence:** Record #39. "Halves Adam communication overhead with minimal
accuracy loss."

**What it does:** Only update Adam parameters (embeddings, scalars) on odd steps. Muon
updates every step. Works because embedding/gate weights change slowly.

**Applicability:** Direct. Our Adam params are tok_emb (524K params) and scalars (~20K).
The tok_emb gradient still needs allreduce every step for DDP, but the Adam state update
(momentum buffers, step) can be skipped on even steps.

**Estimated gain:** 1-2% communication savings. Small because our Adam params are small
relative to Muon params.

**Effort:** Trivial. `if step % 2 == 1: adam_optim.step()`.

#### 15H. Compiled Adam

**nanogpt evidence:** Record #56. Uses `@torch.compile(dynamic=False, fullgraph=True)`.

**What it does:** Compile the Adam update step. `dynamic=False` is critical — "Must use
dynamic=False or else it's much slower."

**Applicability:** We use `torch.optim.Adam` with `fused=True`. Compiling on top of
fused Adam may or may not help. Worth benchmarking.

**Estimated gain:** 1-2% step time.

**Effort:** Low.

### Revised systems priority incorporating nanogpt evidence

| # | Item | Evidence | Estimated gain | Effort | Risk |
|--:|------|----------|----------------|--------|------|
| 1 | reduce_scatter replacing DDP | nanogpt #22-24,36 | 5-10% tok/s on 8x | High | Medium |
| 2 | BF16 weights + mantissa buffer | nanogpt #57 | 3-8% tok/s | Medium | Low |
| 3 | Fused linear_relu_square Triton | nanogpt #59 | 1-3% tok/s | Medium | Medium |
| 4 | XXT/XTX symmetric Muon kernels | nanogpt #27 | 1-2% tok/s | Low-Med | Low |
| 5 | BF16 cross entropy (drop .float()) | nanogpt #37 | 0.5-1% tok/s | Trivial | Low |
| 6 | Async data prefetch | nanogpt #33 | 1-3% tok/s | Low | Low |
| 7 | Packed QKV | Our analysis | 2-5% tok/s | Low | Low |
| 8 | DDP bucket_cap_mb + static_graph | Known PyTorch | 1-3% tok/s on 8x | Trivial | Low |
| 9 | Persistent Muon buffer | Our analysis | 1-4% tok/s | Low | Low |
| 10 | Adam every other step | nanogpt #39 | 1-2% comm | Trivial | Low |
| 11 | Compiled Adam | nanogpt #56 | 1-2% tok/s | Low | Low |
| 12 | Turbo-Muon (4 NS steps) | Paper 2512.04632 | 3-8% tok/s | Low | Low |

**Compounded estimate:** Tier 1 (items 5-12, LOW effort) = 10-20% step time.
All items including High effort = 25-40%. This is significantly higher than our
previous 5-15% estimate, backed by nanogpt's actual measurements.

### nanogpt negative results relevant to us

1. **GQA at small scale doesn't help** — we use GQA (8q/4kv) and can't change it.
   nanogpt found GQA savings don't compensate for capacity loss at dim=768. This
   suggests our GQA config may be suboptimal but it's fixed in the baseline.

2. **Per-head gradient orthonormalization** — "Only 1% speedup on 1xH100. Not worth
   the complexity." Don't try to run NS at per-head granularity.

3. **BF16 weights WITHOUT mantissa** — "Substantially detrimental." Don't try BF16
   weights without the mantissa buffer trick.

4. **Removing logit softcap** — "Training diverges." Fuse it, don't remove it.

5. **CUDA Graphs for training** — Nobody has tried this in nanogpt either, despite
   77 records. Dynamic control flow makes it hard. Confirms our Section 13 assessment.
