# Parameter Golf Competition Tracker

Last updated: 2026-03-22 1:00 AM ET (FULL 253-PR sweep + author classifications)
Auto-check: every 6 hours
Legend: HS=high school, UG=undergrad, Grad=grad student, Pro=professional, Sr=senior/founder, ?new=throwaway account

---

## Confirmed Leaderboard (from README - maintainers behind on merges)

| Rank | Score | Author | Run | Date |
|------|-------|--------|-----|------|
| 1 | 1.1428 | thwu1 | 10L Int5-MLP + BigramHash(10240), SWA(0.4), WD=0.04 | 03-20 |
| 2 | 1.1458 | Raahil Shah | 3x MLP + SmearGate + BigramHash + OrthoInit + Muon WD + SWA | 03-20 |
| 3 | 1.1502 | aruniyer | 11L, 3x MLP, int6 QAT, zstd-22, WD=0.04, sliding eval | 03-20 |
| 4 | 1.1556 | aquariouseworkman | SmearGate + BigramHash + 3x MLP + int6 STE QAT + sliding eval | 03-19 |
| 5 | 1.1586 | yahya010 | 10L, int6 QAT + zstd-22, MLP 1344, Muon 0.99 | 03-19 |
| 6 | 1.1630 | aquariouseworkman | Int6 block + int8 embed + 3x MLP + sliding eval | 03-19 |
| 7 | 1.1748 | notapplica | Spectral embed init + resid mix + 10L + Muon WD | 03-19 |
| 8 | 1.1925 | Matthew Li | Sliding window eval stride=64 | 03-19 |
| 9 | 1.1928 | samacqua | LoRA TTT | 03-19 |
| 10 | 1.2014 | Spokane Way | 4k seq length | 03-19 |
| 11 | 1.206 | Spokane Way | 2048 seq length | 03-18 |
| 12 | 1.2147 | Nan Liu | 10L mixed int8/int6 | 03-18 |
| 13 | 1.2197 | Renier Velazco | FP16 Tied Embed + LR tuning | 03-18 |
| 14 | 1.2244 | Baseline | 9L 512dim 1024vocab | 03-18 |

---

## All Submissions - Complete Ranked Table

Total PRs: 253 | Scored: 174 | Unscored: 79

| Rank | Score  | PR   | Author                | Summary                                                                                    | Date  | Type       | Who  |
| ---- | ------ | ---- | --------------------- | ------------------------------------------------------------------------------------------ | ----- | ---------- | ---- |
| 1    | 1.0238 | #168 | spokane-way           | SOTA Attempt: Paid prefix (val_bpb=1.0238)                                                 | 03-20 | —          | ?new |
| 2    | 1.1246 | #374 | unnir                 | Record: 11L + Tight SWA + Shared VE128 + Partial RoPE + LN Scale + XSA4 (val_bpb: 1.1246)  | 03-21 | Record     | Grad |
| 3    | 1.1248 | #315 | jfprincz              | Record: 11L Partial RoPE + LN Scale + EMA + XSA4 (val_bpb: 1.1248)                         | 03-21 | Record     | —    |
| 4    | 1.1254 | #338 | alertcat              | Record: 11L XSA+EMA+TTT, sliding val_bpb=1.1254 (3-seed mean 1.1256)                       | 03-21 | Record     | —    |
| 5    | 1.1271 | #287 | jfprincz              | Record: 11L XSA + EMA + Int6 MLP3x + WD=0.04 (val_bpb: 1.1271)                             | 03-20 | Record     | —    |
| 6    | 1.1303 | #254 | timowhite88           | Record: FarnsworthEngine v1 — TTT + 11L Int6 MLP3x, val_bpb=1.1303                         | 03-20 | Record     | Pro  |
| 7    | 1.1307 | #265 | unnir                 | Record: 11L + Efficient Partial XSA (val_bpb: 1.1307)                                      | 03-20 | Record     | Grad |
| 8    | 1.1318 | #198 | jfprincz              | 11-Layer Int6 + WD=0.04 + SWA + FA3 (val_bpb: 1.1318)                                      | 03-20 | —          | —    |
| 9    | 1.1320 | #332 | saml212               | Record: 12L Gradient-Guided Quant + Partial RoPE + LN Scale + EMA + XSA4 (val_bpb: 1.1320) | 03-21 | Record     | Pro  |
| 10   | 1.1326 | #223 | 0xjaishy              | Draft: SOTA+ TTT + RoPE50K + EMA + Curriculum (pending H100 run)                           | 03-20 | —          | Pro  |
| 11   | 1.1328 | #369 | signalrush            | Submission: 11L NTK-RoPE + FA3 + Batch524K + XSA4 + EMA (val_bpb=1.1328)                   | 03-21 | —          | ?new |
| 12   | 1.1354 | #290 | ibarrajo              | Record: 11L + Partial XSA + TTT + BatchOpt (val_bpb=1.1354)                                | 03-21 | Record     | Sr   |
| 13   | 1.1357 | #307 | dennisimoo            | Record: 11L XSA4 + EMA + Batch524K + zstd fallback (val_bpb: 1.1357)                       | 03-21 | Record     | —    |
| 14   | 1.1364 | #339 | sheeki03              | Record: 11L Backout + Int6 + SWA (val_bpb: 1.1364)                                         | 03-21 | Record     | —    |
| 15   | 1.1377 | #64  | yesbhautik            | Record: 11L XSA + EMA + TTT (mean val_bpb=1.1377)                                          | 03-19 | Record     | Pro  |
| 16   | 1.1399 | #349 | Mapika                | Record: 11L XSA + EMA + Int5-MLP (val_bpb=1.1399)                                          | 03-21 | Record     | Pro  |
| 17   | 1.1400 | #236 | saml212               | 4 the Leaderboard: 11L Int6 + SmearGate + Batch Optimization (val_bpb=1.1400)              | 03-20 | —          | Pro  |
| 18   | 1.1401 | #376 | anthony-maio          | Record: 9L MLP3x Full Stack + Custom Kernel Pipeline, val_bpb=1.1401                       | 03-21 | Record     | Pro  |
| 19   | 1.1401 | #212 | mrdavtan              | Record: 11L XSA + EMA + TTT + Partial RoPE + LN Scale — val_bpb=1.1401                     | 03-20 | Record     | —    |
| 20   | 1.1402 | #267 | andrewgcodes          | Record: val_bpb: 1.14020 [tested 3x on 8xh100]                                             | 03-20 | Record     | UG   |
| 21   | 1.1403 | #274 | haikosys              | [Record] Stride-32 + Warmdown/Muon Tuning on SOTA #1: mean val_bpb=1.1403                  | 03-20 | Record     | ?new |
| 22   | 1.1426 | #360 | MultiFe22             | Non-record: QAT & EMA negative results on SOTA stack (val_bpb=1.1426)                      | 03-21 | Non-record | Pro  |
| 23   | 1.1433 | #76  | unixmadtoonslab       | 12L Int5-MLP + SmearGate + BigramHash + SWA (val_bpb 1.1433)                               | 03-19 | —          | —    |
| 24   | 1.1436 | #303 | sseanliu              | [Non-record] XSA + EMA + TTT: Negative interaction study (val_bpb=1.1436)                  | 03-21 | Non-record | Grad |
| 25   | 1.1442 | #317 | chris-buckley         | Record: 11L XSA4 + EMA + TTT + Int6 MLP3x (val_bpb=1.1442)                                 | 03-21 | Record     | —    |
| 26   | 1.1444 | #348 | fbedev                | Submission/qat bigram12k stride32                                                          | 03-21 | —          | HS   |
| 27   | 1.1448 | #306 | xuafeng               | Non-record: QAT Int5/Int6 on #1 architecture (1.14476 BPB)                                 | 03-21 | Non-record | —    |
| 28   | 1.1449 | #305 | Naazimsnh02           | 12L Group-INT4 MLP + INT6 Attn + BigramHash(10240) — val_bpb 1.1449 pre-quant              | 03-21 | —          | —    |
| 29   | 1.1450 | #327 | Ananddna              | Submission TrigramHash + PartialRoPE + HeadTemp + stride32 (val_bpb: 1.1450)and            | 03-21 | —          | Pro  |
| 30   | 1.1455 | #264 | stukenov              | 11L Int5-MLP + TTT-SGD + SmearGate + SWA (1.1455 BPB)                                      | 03-20 | —          | —    |
| 31   | 1.1462 | #325 | Aum08Desai            | Add Looped Transformer Design non-record submission (non tuned)                            | 03-21 | Non-record | —    |
| 32   | 1.1472 | #179 | devin-cog             | Record: 11L, int6+zstd, decoupled WD (val_bpb = 1.1472)                                    | 03-20 | Record     | —    |
| 33   | 1.1477 | #295 | gowtham0992           | [Record Submission] QAT Int5/Int6 + Backout + U-Net Skips + BigramHash(10240) + SWA50 — va | 03-21 | Record     | Pro  |
| 34   | 1.1478 | #150 | yahya010              | Record: 11L Int6 QAT + SmearGate + OrthoInit + SWA + TTT (val_bpb=1.1478)                  | 03-20 | Record     | Grad |
| 35   | 1.1480 | #194 | baudrillardsgh0st     | 11L Int6 QAT + Per-Dim SmearGate + SWA: 1.1480 BPB (3-seed mean)                           | 03-20 | —          | Sr   |
| 36   | 1.1487 | #331 | Rhodrium              | 10L MLP3x + BigramHash(2048) + SWA + Stride-32: 1.1487 BPB                                 | 03-21 | —          | —    |
| 37   | 1.1497 | #364 | shikhar1729           | Record: Batch-Optimized 524K + Warmdown 4000 (val_bpb 1.1497)                              | 03-21 | Record     | Pro  |
| 38   | 1.1497 | #362 | mkenney2              | Record: 11L Int6+Zstd MLP3x SmearGate BigramHash OrthoInit MuonWD EMA (mean val_bpb=1.1497 | 03-21 | Record     | —    |
| 39   | 1.1502 | #192 | baudrillardsgh0st     | Record: 11L Int6 QAT + SmearGate + WD 0.038 (val_bpb=1.1502)                               | 03-20 | Record     | Sr   |
| 40   | 1.1507 | #206 | dexhunter             | Record: Int6 STE + SmearGate + Seq2048 + OrthoInit + RoPE50K + SWA/100 (mean val_bpb=1.150 | 03-20 | Record     | Pro  |
| 41   | 1.1518 | #289 | integrate-your-mind   | SmearGate + BigramHash + Int6 + SWA + U-Net Skips (1.1518 BPB)                             | 03-21 | —          | Pro  |
| 42   | 1.1520 | #302 | JackYoung27           | Non-record: 11L int5/int6 + XSA + online TTT w/ decay prior (single-run val_bpb=1.1520)    | 03-21 | Non-record | —    |
| 43   | 1.1524 | #164 | jfprincz              | Submission: OrthoInit + Int6 MLP3x + SmearGate + BigramHash (val_bpb: 1.1524)              | 03-20 | —          | —    |
| 44   | 1.1532 | #173 | tamoghnokandar        | Record submission : Int6 + MLP 3x + Flash Attention 3 + NorMuon, val_bpb = 1.1532          | 03-20 | Record     | Grad |
| 45   | 1.1537 | #174 | Julz19                | Add ContextFuse-2048-BigramSmear submission                                                | 03-20 | —          | Pro  |
| 46   | 1.1539 | #135 | unnir                 | Record: OrthoInit + Int6 MLP3x + BigramHash + SmearGate (val_bpb: 1.1539)                  | 03-19 | Record     | Grad |
| 47   | 1.1541 | #230 | MatthewHRockwell      | Record: Int6 + MLP 3x + NorMuon + SmearGate + BigramHash + OrthoInit + Sliding Window, val | 03-20 | Record     | Pro  |
| 48   | 1.1541 | #219 | alertcat              | Non-record: 12L Int5-MLP + Int6-Attn mixed quantization, val_bpb=1.1541                    | 03-20 | Non-record | —    |
| 49   | 1.1548 | #215 | JayCheng113           | Record: 11L Low-Rank Q192 (val_bpb=1.1548)                                                 | 03-20 | Record     | UG   |
| 50   | 1.1551 | #201 | machdragon            | LAWA-EMA frontier fork (pr198 base, SWA -> LAWA val_bpb=1.1551)                            | 03-20 | —          | —    |
| 51   | 1.1554 | #252 | greqone               | Add PR114 RunPod H100 SXM non-record submission                                            | 03-20 | Non-record | —    |
| 52   | 1.1565 | #333 | mahsumaktas           | 11L XSA4 + SmearGate + BigramHash + SWA + RoPE50K (mean val_bpb=1.1565, 3 seeds)           | 03-21 | —          | Pro  |
| 53   | 1.1574 | #366 | shivnarainms22        | Non-record: 10L Int5-MLP + TTT + Backout Connection  (val_bpb=1.1574 on 8xH100 SXM)        | 03-21 | Non-record | —    |
| 54   | 1.1574 | #365 | outsourc-e            | submission: 10L Int5-MLP + Aggressive Warmdown (WD=20000) — targeting <1.14 bpb            | 03-21 | —          | —    |
| 55   | 1.1574 | #114 | saml212               | #1 on leaderboard: val_bpb=1.1574 — Int6 + MLP 3x + selective precision + optimized long-c | 03-19 | —          | Pro  |
| 56   | 1.1575 | #273 | dentity007            | Non-record: 10L Int6 QAT + SmearGate + SWA (val_bpb=1.1575)                                | 03-20 | Non-record | Sr   |
| 57   | 1.1594 | #128 | rsavitt               | Record: Int6 MLP3x + STE QAT + Sliding Window (val_bpb=1.1594)                             | 03-19 | Record     | —    |
| 58   | 1.1596 | #251 | kshitizz36            | Add SP4096 11L432 MLP3x Int6+Zstd Momentum99 record (val_bpb=1.1596)                       | 03-20 | Record     | —    |
| 59   | 1.1598 | #191 | chris-buckley         | Record: Compression-Funded MLP3x (val_bpb=1.1598)                                          | 03-20 | Record     | —    |
| 60   | 1.1600 | #122 | mtybadger             | Record: Sliding Window Eval, 2048 Vocab Size, fp16 embeddings, SWA, NorMuon, FA3; mean_val | 03-19 | Record     | UG   |
| 61   | 1.1601 | #222 | ansh-deriv            | Non-record: WiderMLP + FP16 Embed + Stride-32 (val_bpb=1.1601)                             | 03-20 | Non-record | UG   |
| 62   | 1.1602 | #156 | dexhunter             | feat(record): Int6 STE + NorMuon + SWA + Sliding Window (val_bpb=1.16019)                  | 03-20 | Record     | Pro  |
| 63   | 1.1605 | #99  | takhir-iota           | submission: Int6 MLP3x + Late-K Passthrough + SlidingWindow (val_bpb: 1.1605)              | 03-19 | —          | Sr   |
| 64   | 1.1605 | #88  | seanward              | Record: Int6 MLP3x + MTP + Sliding Window Eval (val_bpb=1.1605)                            | 03-19 | Record     | Pro  |
| 65   | 1.1609 | #330 | bopmite               | Non-record: 11L Int6 + Online Logit Bias (val_bpb=1.1609)                                  | 03-21 | Non-record | —    |
| 66   | 1.1618 | #102 | unnir                 | Int6 MLP3x + Tuned LR + SmearGate + SlidingWindow (val_bpb: 1.1618)                        | 03-19 | —          | Grad |
| 67   | 1.1622 | #89  | vmfunc                | record:  val_bpb=1.1622, NorMuon + int6 STE + SWA + sliding window                         | 03-19 | Record     | Pro  |
| 68   | 1.1623 | #160 | ChaseWNorton          | Record: MLP3x + Int8 Tok Emb + Grouped LZMA + Sliding Window (val_bpb=1.1623)              | 03-20 | Record     | —    |
| 69   | 1.1624 | #209 | JWLBOYCE              | Add non-record 11L int6 challenger 8xH100 attempt                                          | 03-20 | Non-record | —    |
| 70   | 1.1628 | #286 | chris-buckley         | Record: 10L Int5-MLP + SmearGate + BigramHash + Late QAT (val_bpb=1.1628)                  | 03-20 | Record     | —    |
| 71   | 1.1629 | #187 | Idan3011              | Record: Pre-Enrichment + Encoder Recurrence + XSA + SmearGate + BigramHash (val_bpb=1.1629 | 03-20 | Record     | —    |
| 72   | 1.1631 | #147 | ankitmaloo            | Record/smaller batch sota, val_bpb 1.16314679 (post-quant, int6+zlib, sliding eval)        | 03-20 | Record     | —    |
| 73   | 1.1632 | #66  | arjun-krishna1        | ArjunAutoResearch: MLP 3x + STE int6 QAT + seq4096 + sliding window. val_bpb 1.1632        | 03-19 | —          | Pro  |
| 74   | 1.1634 | #373 | JoeProAI              | Record: SwiGLU + BigramHash + SWA, val_bpb=1.1634 (8xH100 verified)                        | 03-21 | Record     | —    |
| 75   | 1.1642 | #123 | saikrishnarallabandi  | Record: Vocab 4096 + MLP 3x + Sliding Window Eval (mean val_bpb=1.1642, 3 seeds)           | 03-19 | Record     | Sr   |
| 76   | 1.1645 | #296 | sseanliu              | [Non-record] Meta-Learned TTT + Error-Guided Adaptation Analysis (val_bpb=1.1645)          | 03-21 | Non-record | Grad |
| 77   | 1.1648 | #107 | m0at                  | Int6+zstd MLP1488 + Sliding Window + QAT + Tuned LR (val_bpb=1.1648)                       | 03-19 | —          | —    |
| 78   | 1.1659 | #352 | sp00mm                | Memory Tokens + Mixed Quantization (val_bpb: 1.1659)                                       | 03-21 | —          | UG   |
| 79   | 1.1659 | #70  | jfprincz              | Submission: Wider MLP 3x + int6 quant + sliding window eval, val_bpb=1.1659                | 03-19 | —          | —    |
| 80   | 1.1666 | #137 | abhishekgahlot2       | Record: Int6 + MLP 3x + STE QAT + NorMuon + sliding window (val_bpb 1.1666)                | 03-19 | Record     | Pro  |
| 81   | 1.1668 | #312 | chanwoo-park-official | Record: Int6 + Canon ACD (K=3) + Muon WD 0.04 + SWA + Sliding Eval (val_bpb=1.1668)        | 03-21 | Record     | Grad |
| 82   | 1.1669 | #170 | baudrillardsgh0st     | Record: Int6 QAT + SmearGate + Muon WD (val_bpb=1.1669)                                    | 03-20 | Record     | Sr   |
| 83   | 1.1670 | #81  | polarizedfortnite-cpu | Record: SwiGLU + MLP 3x + Int6 + LoRA TTT, val_bpb=1.1670 (8xH100)                         | 03-19 | Record     | —    |
| 84   | 1.1697 | #299 | Mistobaan             | [Non-record] LoRA TTT + HParams (val_bpb=1.16973333)                                       | 03-21 | Non-record | —    |
| 85   | 1.1698 | #347 | FlashyFlash3011       | LongContext 4096 + Full SOTA Stack & QAT Int4 → 16 Layers                                  | 03-21 | —          | —    |
| 86   | 1.1702 | #326 | crony-io              | [Non-Record] QAT + NTK-4096 Eval + Cosine Warmdown + Aggressive SWA                        | 03-21 | Non-record | Pro  |
| 87   | 1.1702 | #117 | trovatochris          | submission: Int6 MLP3x + QAT + SlidingWindow (val_bpb: 1.1702)                             | 03-19 | —          | —    |
| 88   | 1.1704 | #249 | kvmukilan             | non-record: int6 3xMLP + cosine warmdown (1.1704 bpb)                                      | 03-20 | Non-record | —    |
| 89   | 1.1708 | #69  | TevBenji              | SubSixteen v2: Int6 QAT + MLP 3x + SWA + Sliding Window (val_bpb 1.1708)                   | 03-19 | —          | UG   |
| 90   | 1.1719 | #211 | dubthecat             | Add WaveletWeightedWidenet submission directory with README and metadata                   | 03-20 | —          | —    |
| 91   | 1.1722 | #329 | lee101                | Add lzma6 submission (1.172 bpb, 10min_16mb)                                               | 03-21 | —          | Pro  |
| 92   | 1.1725 | #190 | newjordan             | The Stinky Frost Recipe — 1.1725 BPB                                                       | 03-20 | —          | Pro  |
| 93   | 1.1732 | #176 | GLDRoger              | Add submission: 10L Slide64 Mid6, val_bpb=1.1732                                           | 03-20 | —          | —    |
| 94   | 1.1747 | #256 | IvGolovach            | DenseContextQuantTrim 8xH100: 1.1779 val_bpb                                               | 03-20 | —          | Pro  |
| 95   | 1.1748 | #175 | anthony-maio          | Record: TTT LoRA + SOTA Training (10L MuonWD FP16Emb OvertoneInit)                         | 03-20 | Record     | Pro  |
| 96   | 1.1753 | #217 | kshitizz36            | Record: SP4096 int6+zstd 10L496 overtone+phase sliding (val_bpb=1.1753)                    | 03-20 | Record     | —    |
| 97   | 1.1764 | #96  | saml212               | Sliding Window + Long-Context Training: val_bpb=1.1764                                     | 03-19 | —          | Pro  |
| 98   | 1.1770 | #367 | ksang123              | Non-record: BitNet b1.58 - 68M ternary params, val_bpb=1.1770, systematic analysis of tern | 03-21 | Non-record | —    |
| 99   | 1.1787 | #310 | vishesh9131           | Record: 10L Seq2048 TTT LoRA WarmdownQuant (val_bpb=1.1787)                                | 03-21 | Record     | Pro  |
| 100  | 1.1792 | #205 | xinpw8                | MetaStack v3: 1.1792 sliding bpb, 10L BigramHash SmearGate OrthoInit SWA                   | 03-20 | —          | —    |
| 101  | 1.1807 | #301 | lookin-zz             | Non-record: Int6 QAT + MLP1472 + SlidingWindow + TTT (val_bpb=1.1807)                      | 03-21 | Non-record | —    |
| 102  | 1.1812 | #172 | GMaN1911              | Add 3xMLP + Mixed Quant + Blockade/Sigma submission (val_bpb: 1.1812)                      | 03-20 | —          | Pro  |
| 103  | 1.1844 | #182 | mihir-s-05            | Non-record: Linearized Neural Memory + TTT (val_bpb=1.1844)                                | 03-20 | Non-record | —    |
| 104  | 1.1864 | #321 | andreanjos            | Add record: Optimizer Tuning + Sliding Window Eval (val_bpb=1.1864)                        | 03-21 | Record     | —    |
| 105  | 1.1876 | #155 | peytontolbert         | Record: sliding eval, FP16 tied embeddings, 10 layers, Muon WD 0.02, overtone init, and ph | 03-20 | Record     | —    |
| 106  | 1.1893 | #197 | machdragon            | Non-record: staging profile (LAWA + slide eval) on 8xH100 (val_bpb=1.18926428)             | 03-20 | Non-record | —    |
| 107  | 1.1899 | #221 | shajalahamedcse       | Submission: 10L + Sliding Window eval (mean val_bpb=1.1899)                                | 03-20 | —          | Pro  |
| 108  | 1.1913 | #355 | josusanmartin         | Add non-record BigramHash4096 + MLP992 + LR0.08 + Slide64 submission                       | 03-21 | Non-record | Sr   |
| 109  | 1.1914 | #309 | NewyorkDev            | Record: CLASE-Quant adaptive layer quantization (val_bpb=1.1914)                           | 03-21 | Record     | —    |
| 110  | 1.1925 | #142 | ankitmaloo            | Record: Quant Quality: val_bpb=1.1925                                                      | 03-20 | Record     | —    |
| 111  | 1.1929 | #199 | mrdavtan              | Non-record: SWA and doc-isolated eval ablation — two negative findings at stride=64        | 03-20 | Non-record | —    |
| 112  | 1.1938 | #92  | saikrishnarallabandi  | Record: 8192 Vocab, Sliding Window Eval, Selective Quantization; 1.194 val_bpb             | 03-19 | Record     | Sr   |
| 113  | 1.1957 | #161 | santosh5541           | Record:Add TTT-LoRA 512d submission (val_bpb=1.1957)                                       | 03-20 | Record     | Grad |
| 114  | 1.1973 | #169 | beee003               | Sliding Window Eval + Muon6 (val_bpb 1.1973)                                               | 03-20 | —          | Pro  |
| 115  | 1.2012 | #200 | khasinski             | Record: SP4096 + Int6 QAT + NorMuon (val_bpb=1.2012)                                       | 03-20 | Record     | —    |
| 116  | 1.2029 | #139 | ksang123              | Non-record: BitNet b1.58 — 65M ternary params beat 4-hour baseline in 10 minutes (val_bpb= | 03-19 | Non-record | —    |
| 117  | 1.2035 | #316 | SkywardSyntax         | Non-record: 12L Low-Rank Q + QAT (1xH100, pre-quant 1.2035)                                | 03-21 | Non-record | —    |
| 118  | 1.2036 | #231 | lenguyen1807          | Record: SEQ_LEN=4096 training                                                              | 03-20 | Record     | Pro  |
| 119  | 1.2037 | #368 | MatoTeziTanka         | PROTEUS v4 — non-record submission (val_bpb: 1.2037)                                       | 03-21 | Non-record | Pro  |
| 120  | 1.2052 | #145 | mrdavtan              | Non-record: QAT ablation — int8 QAT overhead exceeds quantization gap recovery             | 03-20 | Non-record | —    |
| 121  | 1.2064 | #244 | simon-marcus          | Non-record: leader-core valid-eval parity run + 1xH100 proxy screens                       | 03-20 | Non-record | Sr   |
| 122  | 1.2075 | #141 | nglain                | Non-record: Systematic Hyperparameter Search (val_bpb=1.2075)                              | 03-20 | Non-record | —    |
| 123  | 1.2089 | #225 | dibdabo               | Non-record: Int6 QAT + 11L 512d + Sliding Window, val_bpb=1.2089                           | 03-20 | Non-record | —    |
| 124  | 1.2091 | #163 | Focus2321             | SwiGLU dim=576 + Sliding Window + Muon WD (1.2091 BPB)                                     | 03-20 | —          | —    |
| 125  | 1.2101 | #136 | ibarrajo              | Record: Seq2048 training + eval (val_bpb=1.2101)                                           | 03-19 | Record     | Sr   |
| 126  | 1.2156 | #85  | hydeh3r3              | Record (pending): 92-experiment autoresearch + sliding window eval, pre-quant val_bpb=1.21 | 03-19 | Record     | —    |
| 127  | 1.2194 | #181 | manfromnowhere143     | Aweb Optimized Baseline — 1.2194 BPB                                                       | 03-20 | —          | Pro  |
| 128  | 1.2196 | #148 | iverbovoy             | Depth Recurrence + Cross-Repeat Skip + Sliding Window Eval                                 | 03-20 | —          | —    |
| 129  | 1.2207 | #334 | nathon-lee            | Non-record: 11L PartialRoPE + LNScale + EMA + SWA + TTT (1xH100 107min, val_bpb=1.2207, 15 | 03-21 | Non-record | —    |
| 130  | 1.2253 | #95  | MatoTeziTanka         | PROTEUS EMA — val_bpb: 1.2253                                                              | 03-19 | —          | Pro  |
| 131  | 1.2320 | #204 | Akasxh                | Add record: INT6 10L SWA NorMuon, val_bpb=1.2320                                           | 03-20 | Record     | Pro  |
| 132  | 1.2355 | #195 | chasewebb             | Add chasewebb 9x512 sp1024 baseline (val_bpb: 1.2355)                                      | 03-20 | —          | Grad |
| 133  | 1.2421 | #370 | SergheiBrinza         | Add submission: Mixed Quantization + BigramHash + SWA (val_bpb 1.2421)                     | 03-21 | —          | —    |
| 134  | 1.2427 | #272 | simon-marcus          | Non-record: 10L mixed int5/int6 export reaches ~10.4MB with strong throughput              | 03-20 | Non-record | Sr   |
| 135  | 1.2459 | #343 | joeynyc               | Submission: val_bpb=1.2459 (autoresearch-optimized)                                        | 03-21 | —          | —    |
| 136  | 1.2716 | #319 | Arth-Singh            | Non-record: Depth Recurrence 5x3 — Weight-Shared Looping Transformer (6xH200, val_bpb=1.27 | 03-21 | Non-record | Pro  |
| 137  | 1.2827 | #293 | Nishu2000-hub         | Non-record: Custom sp4096 BPE Tokenizer (1.2827 BPB on 1×H100)                             | 03-21 | Non-record | —    |
| 138  | 1.2838 | #354 | Skrisps26             | [Non-record] MLA + SmearGate + BigramHash + SWA — pre-quant 1.2838 bpb                     | 03-21 | Non-record | —    |
| 139  | 1.2913 | #344 | aryanbhosale          | Non-record: Autoresearch Heads4 + Step-based LR + Sliding Window (1xH100)                  | 03-21 | Non-record | —    |
| 140  | 1.2917 | #193 | KHUCHAN               | Add CTM tail-QAT proxy non-record snapshot                                                 | 03-20 | Non-record | —    |
| 141  | 1.2987 | #146 | swapp1990             | Non-record: Warmdown-Tuned Training (val_bpb=1.2987) on 1xRTX 5090                         | 03-20 | Non-record | —    |
| 142  | 1.2988 | #242 | jamesrziggy           | Crystal Curriculum — TF-IDF curriculum learning by Bee Bytez                               | 03-20 | —          | —    |
| 143  | 1.3003 | #271 | xexyz                 | Non-record: HyperparamTuned KV2 + FP16 Embed                                               | 03-20 | Non-record | —    |
| 144  | 1.3043 | #185 | dttdrv                | Non-record: Wider-shallower 4x768 + QAT (1xH100, 1.3043 bpb)                               | 03-20 | Non-record | Pro  |
| 145  | 1.3360 | #104 | gwelinder             | Non-record: Stacked hyperparameter tuning + eval2048 (RTX 5090, val_bpb 1.336)             | 03-19 | Non-record | Sr   |
| 146  | 1.3446 | #226 | CRouvroy              | Submission: Low-Rank All-Attention (1.3446 bpb)                                            | 03-20 | —          | UG   |
| 147  | 1.3510 | #285 | DanishjeetSingh       | Add non-record local A100 TTT eval-stride0 submission                                      | 03-20 | Non-record | Grad |
| 148  | 1.3529 | #346 | bjbjbjbjbjbj          | Add local baseline reproduction record                                                     | 03-21 | Record     | —    |
| 149  | 1.3825 | #196 | sicauzxl              | Add non-record submission: 8xH100 FineWeb baseline + TTT eval (val_bpb 1.3825)             | 03-20 | Non-record | Pro  |
| 150  | 1.3932 | #266 | User123331            | Non-record: Mixture of Softmax K=2 R=64 (1xH100, 10min, 1.3932 bpb)                        | 03-20 | Non-record | —    |
| 151  | 1.4106 | #284 | DanishjeetSingh       | Add non-record local A100 PR60-stack reproduction                                          | 03-20 | Non-record | Grad |
| 152  | 1.4370 | #108 | kellyvv               | Record: 11L MLP3x + SmearGate + Error Correction Table                                     | 03-19 | Record     | —    |
| 153  | 1.4444 | #228 | hmhm0                 | Record: 10-Layer 4xMLP (val_bpb: 1.4444)                                                   | 03-20 | Record     | —    |
| 154  | 1.5164 | #232 | kellyvv               | Record: 11L MLP3x + SmearGate + Error Correction Table                                     | 03-20 | Record     | —    |
| 155  | 1.5283 | #54  | TheCause              | RQZ-Golf v1: Depth recurrence for parameter efficiency                                     | 03-19 | —          | Pro  |
| 156  | 1.5382 | #263 | Dannybc123            | Non-record: TTT + QAT on Consumer GPU (val_bpb=1.5382)                                     | 03-20 | Non-record | —    |
| 157  | 1.5890 | #213 | estesryan             | Non-record submission: recurrent 512 L3 6k (8x H100, 224s)                                 | 03-20 | Non-record | —    |
| 158  | 1.6114 | #247 | riatzukiza            | Non-record: local RTX 4070 SP1024 8x512 KV4 seq768 500-step run                            | 03-20 | Non-record | —    |
| 159  | 1.6231 | #248 | riatzukiza            | Non-record: local RTX 4070 SP1024 8x512 KV4 500-step run                                   | 03-20 | Non-record | —    |
| 160  | 1.6572 | #258 | riatzukiza            | Non-record: local RTX 4070 SP1024 7x512 KV4 500-step run                                   | 03-20 | Non-record | —    |
| 161  | 1.6577 | #276 | riatzukiza            | Non-record: local RTX 4070 shared-depth RMS interface v0                                   | 03-20 | Non-record | —    |
| 162  | 1.6660 | #240 | riatzukiza            | Non-record: local RTX 4070 SP1024 7x512 KV2 500-step run                                   | 03-20 | Non-record | —    |
| 163  | 1.6795 | #288 | trasnake87            | Non-record: Content-Dependent SmearGate (1.6795 BPB, RTX 4070)                             | 03-20 | Non-record | —    |
| 164  | 1.7232 | #313 | my-sonicase           | non-record: LR warmdown on 1x A40 (1.723 bpb, 8.40MB)                                      | 03-21 | Non-record | —    |
| 165  | 1.7510 | #126 | Athenox14             | Non-record: BitNet b1.58 + depth recurrence + NorMuon (1.7510 BPB, 3.78 MB)                | 03-19 | Non-record | Pro  |
| 166  | 1.8338 | #356 | sjp611                | Non-record: PR315 repro on 1xH100 PCIe, int6+zstd (val_bpb=1.8338)                         | 03-21 | Non-record | —    |
| 167  | 1.8389 | #237 | takoyakisoft          | Add 10L 4K long-context negative-result submission                                         | 03-20 | —          | —    |
| 168  | 1.8440 | #56  | cschubiner            | Add Deep14x416 KV2 non-record MLX submission (val_bpb=1.8440)                              | 03-19 | Non-record | Pro  |
| 169  | 1.8480 | #220 | timothywangdev        | [WIP] SSM LRU Baseline — First State Space Model Submission                                | 03-20 | —          | —    |
| 170  | 1.8522 | #345 | anandks2006           | Non-record: DART - Differential Attention Recurrent Transformer (Student submission, Keral | 03-21 | Non-record | —    |
| 171  | 1.9011 | #342 | adhyaay-karnwal       | Non-record: MLX-Optimized 12L 416d with SmearGate + BigramHash (val_bpb=1.9011, Mac)       | 03-21 | Non-record | HS   |
| 172  | 1.9105 | #68  | swangai7178           | Add 1.9105 BPB submission (M3 Pro Optimized)                                               | 03-19 | —          | Pro  |
| 173  | 1.9588 | #328 | kingjulio8238         | Non-record: MLX prototyping harness with validated technique stack (val_bpb=1.9588, Mac)   | 03-21 | Non-record | —    |
| 174  | 1.9998 | #300 | Janksuu               | Non-record: Shared-Core 8/12 @ 896 on 1xH100 SXM (1.9998 val_bpb)                          | 03-21 | Non-record | Pro  |

## Unscored / WIP / Infrastructure PRs

| PR | Author | Summary | Date | Type | Who |
|----|--------|---------|------|------|
| #375 | charmquark1984 | Non-record: Negative results & insights from 24hrs on 8xH100 | 03-21 | Non-record | — |
| #363 | evangelinehelsinki | Non-record: Depth Recurrence + Quantization Error Amplification Finding | 03-21 | Non-record | HS |
| #361 | adityagupta26 | feat: Ultimate SOTA submission - 10L Model, Mixed Int6 QAT, and TTT/LoRA Evaluation | 03-21 | — | — |
| #358 | adityagupta26 | Feature/sota optimizations | 03-21 | — | — |
| #357 | adityagupta26 | docs: add TIPS.md and resolve environment dependency issues (#280, #82, #43) | 03-21 | — | — |
| #341 | tobiascanavesi | Add Hybrid Depth-Recurrent Transformer submission | 03-21 | — | — |
| #340 | starfly-web | V2 Prototype: SwiGLU + Dropout + MuonWD + MidLayerLoop | 03-21 | — | — |
| #336 | jackopenn | Add hypernetwork approach and issue #140 analysis summary | 03-21 | — | — |
| #323 | megnat05-tmm | Minimal recurrent motif (sb1 rs2 g0.18) – non-record submission | 03-21 | Non-record | — |
| #322 | romainsantoli-web | 11L SmearGate + BigramHash(10240) + Causal TTT + Mixed Int5/Int6 + SWA | 03-21 | — | — |
| #320 | megnat05-tmm | Minimal recurrent motif (sb1 rs2 g0.18) – non-record submission | 03-21 | Non-record | — |
| #318 | sseanliu | Neural Cache: Cross-Window KV Caching for Extended Eval Context (research proposal) | 03-21 | — | Grad |
| #314 | aravhawk | 11L Int4 MLP QAT + BigramHash(10240) + SWA | 03-21 | — | Sr |
| #311 | small-cactus | Non-record: Internal control port on the PR180 stack | 03-21 | Non-record | — |
| #308 | gb250e | TPI-001 eval-first monkey model prototype | 03-21 | — | — |
| #304 | Bortlesboat | Non-record: QAT + Neural Cache + LoRA TTT | 03-21 | Non-record | Pro |
| #298 | MrINVISO | Ultimate recurrent: 21 techniques — depth recurrence, novel ops | 03-21 | — | — |
| #297 | davidpuertolas | Late STE QAT + Int6 MLP3x + SmearGate + BigramHash + OrthoInit + Overtone + SWA + SGD TTT (int6+zstd | 03-21 | — | Pro |
| #291 | mohosy | Non-record: 11L EMA + XSA + Int6 MLP3x (pending compute) | 03-21 | Non-record | UG |
| #283 | Cwarren15-A | Tier 6: PPM-C eval-time context mixer (standalone + neural mixing) | 03-20 | — | — |
| #282 | Cwarren15-A | Phase 1: Int6 quant + zstd + sliding window eval + 10L 3xMLP | 03-20 | — | — |
| #279 | Evreu1pro | Title: AtomLogic v3.2 Universal SOTA - 1.15 BPB Target | 03-20 | — | — |
| #277 | mohosy | Non-record: 11L Int6 + XSA + TTT + SmearGate + BigramHash (pending compute) | 03-20 | Non-record | UG |
| #268 | brn-mwai | Record: 11L Int6 + SmearGate + BigramHash + Depth Recurrence | 03-20 | Record | Pro |
| #261 | MnemoTek | Create main.pyInitial compact language model baseline | 03-20 | — | — |
| #260 | Kevxn97 | [codex] Validate sliding-window post-quant evaluation on 1xH100 proxy | 03-20 | — | — |
| #259 | outsourc-e | submission: QK Gain Init 1.2 + Sliding Window Eval (stride=64) | 03-20 | — | — |
| #250 | Complexity-ML | Complexity MoE v4: Token-Routed I64 + PID + CUDA Scatter + Int6 (26.5M params) | 03-20 | — | — |
| #241 | kellyvv | [Non-record] Eval-time Adaptation: Stride-OGD + Two-Pass + NTK-RoPE | 03-20 | Non-record | — |
| #238 | kellyvv | [Non-record] Quantization Findings: SWA Reversal + Int5 Failure | 03-20 | Non-record | — |
| #235 | zeyuchenphd | Draft: 6-bit QAT + SP4096 + Layer Recurrence 5×2, requesting compute | 03-20 | — | — |
| #234 | RyanLisse | feat(mlx,autoresearch): harden search reliability and mlx iteration safety | 03-20 | — | Sr |
| #233 | FlorinelTudor | Add sliding-window eval to MLX trainer | 03-20 | — | — |
| #229 | hooiv | [Non-Record] Zeno: 10-Layer Muon with Full CastedLinear Capacity (18.5M params) | 03-20 | Non-record | Pro |
| #227 | riatzukiza | docs: add local NVIDIA GPU workflow | 03-20 | — | — |
| #224 | Complexity-ML | Complexity MoE + PID Dynamics (Token-Routed I64) | 03-20 | — | — |
| #216 | alons23 | Ternary Universal Transformer — 15.6MB, bfloat16, Muon optimizerAdd ternary Universal Transformer su | 03-20 | — | — |
| #214 | wojciechkowalczyk11to-tech | Submission: GANGUS × NEXUS — Multi-Model AI Orchestrator (gangus-nexus) | 03-20 | — | — |
| #203 | LexHarie | [WIP] wallclock-aware context curriculum | 03-20 | — | — |
| #189 | shuofengzhang | Harden TTT doc splitting for missing/trailing BOS edge cases | 03-20 | — | — |
| #188 | reimorster | ROCm Support | 03-20 | — | Pro |
| #183 | anantdgoel | Non-record: Cache LM + LoRA TTT (negative result on cache, positive on TTT) | 03-20 | Non-record | — |
| #177 | magungh1 | Record: WD + FP16 Embed + Warmdown (val_bpb=TBD) | 03-20 | Record | — |
| #171 | FlorinelTudor | Add MLX knobs for record config parity | 03-20 | Record | — |
| #167 | SkywardSyntax | Depth Recurrence via Layer Sharing (3 shared blocks → 1/3 params, matched BPB) | 03-20 | — | — |
| #166 | chinesepowered | Record: Long Context + All Optimizations submission | 03-20 | Record | — |
| #165 | jtakahashi0604 | [WIP] jtakahashi0604 - tiny experiments | 03-20 | — | — |
| #154 | evnkm | Non-record: Cross-layer parameter sharing + 4-bit QAT (RecurrentGPT) | 03-20 | Non-record | UG |
| #153 | RogueTex | Add strong-submission eval pipeline and ablation tooling | 03-20 | — | Grad |
| #149 | pleasedontddosme | Add Combined Int6 + QAT + Sliding Window submission | 03-20 | — | — |
| #143 | Julz19 | Add ContextFuse-2048 submission | 03-20 | — | Pro |
| #133 | SoumilRathi | Add MLX heavy-share research harness for Parameter Golf | 03-19 | — | UG |
| #131 | Billy1900 | [WIP] add combined optimization, waiting for 8 gpu train | 03-19 | — | — |
| #130 | mohosy | Non-record: Muon-Aware QAT + LAWA + Adaptive LR Scheduling (7 toggleable improvements) | 03-19 | Non-record | UG |
| #127 | matt-wright86 | Non-record: Depth recurrence + widening + QAT + sliding window eval | 03-19 | Non-record | — |
| #125 | akshai0296 | Add non-record 16MB layers7 submission | 03-19 | Non-record | Pro |
| #118 | stukenov | Non-record: 1x RTX 4090 compat smoke (50 steps) | 03-19 | Non-record | — |
| #115 | felix-ab | felix_v1: int6+zstd, fp16 embed, MLP 3x, seq4096, sliding window eval | 03-19 | — | UG |
| #112 | eb1386 | Depth Recurrence 5x3 d672 SwiGLU | 03-19 | — | HS |
| #111 | aamodbhatt | Non-record unlimited-compute: 1-hour 1xH100 warmdown 9x512 | 03-19 | Non-record | — |
| #110 | mr-ashish-panday | Submission: Top-Heavy FFN Allocation + Packed Int6 Export | pending eval | 03-19 | — | — |
| #106 | krammnic | record: 1.158 | 03-19 | Record | Pro |
| #103 | MatthewHRockwell | Non-record: Looped Transformer + LoRA + Skip Connections + NorMuon + SWA + Int6 + Sliding Window | 03-19 | Non-record | Pro |
| #98 | leloykun | Experiment and [WIP] record attempt: Weight decay reduces quantization gap and artifact size | 03-19 | Record | UG |
| #97 | paritoshmmmec | Experiment#1 : Deeper compact | 03-19 | — | Pro |
| #94 | aamodbhatt | Non-record: Warmdown fix (9x512) on 1xH100 10m | 03-19 | Non-record | — |
| #93 | aamodbhatt | Non-record: Compact 12x384 1xH100 10m | 03-19 | Non-record | — |
| #91 | koushikkethamakka | Depth recurrence: 3 unique layers x 3 loops, 1.589 BPB | 03-19 | — | — |
| #90 | gwskier11-design | [codex] add gw kv2 int7 non-record submission | 03-19 | Non-record | — |
| #84 | cschubiner | Add mirrored-recurrence MLX non-record submission | 03-19 | Non-record | Pro |
| #80 | staticplayHub | Add Aria local sweep tooling and non-record 16MB runs | 03-19 | Non-record | Sr |
| #79 | Marvbuster | Depth Recurrence: 3x3x1024 (non-record, pending H100) | 03-19 | Non-record | — |
| #78 | mtybadger | Record: 8192 Vocab Size, NorMuon, Selective Quantization; 1.186 val_bpb | 03-19 | Record | UG |
| #75 | takhir-iota | Add seq4096 sliding-window fp16 tok coarsen record | 03-19 | Record | Sr |
| #74 | takhir-iota | Add seq4096 fp16 tok coarsen record | 03-19 | Record | Sr |
| #72 | sanky369 | Add Parameter Golf submission prep tooling | 03-19 | — | Pro |
| #62 | stpcoder | WIP: Add adaptive eval-time context non-record MLX submission | 03-19 | Non-record | UG |
| #58 | Jenja-N | [WIP] Depth recurrence + BitLinear compression approach | 03-19 | — | — |
| #55 | AVINASH0052 | Add RecursoLM v0 non-record submission scaffold | 03-19 | Non-record | — |

---

## Technique Taxonomy

### Tier 1: Standard Meta (in every competitive entry)
- int6 per-row quantization + zstd-22 compression
- 3x MLP expansion (hidden=1536)
- Sliding window eval (stride=64)
- FP16 tied embedding passthrough
- Muon optimizer + weight decay (0.02-0.04)
- Seq2048 training

### Tier 2: Proven Boosters (in top-10 entries)
- BigramHash (2048-10240 buckets) - explicit bigram statistics
- SmearGate - learned sigmoid gate for local context
- SWA / EMA - weight averaging during warmdown
- OrthoInit + muP scaling
- 11 layers (funded by int6 savings)
- int5 MLP / int6 attention mixed quantization

### Tier 3: Emerging Differentiators (in top-5 claims)
- XSA4 (Exclusive Self Attention on last 4 layers) - arXiv:2603.09078
- EMA (exponential moving average, replacing SWA)
- Tight SWA (only last ~600 steps, scale < 0.2)
- Partial RoPE + LN Scale
- Late QAT (start QAT at 85% wallclock)
- Test-Time Training (TTT) - LoRA or full SGD at eval time
- Batch optimization (524K > 786K for more gradient steps)

### Tier 4: Experimental / Frontier
- Depth Recurrence / Looped Transformers (#319, #325, #148, #91, #79, #54, #58)
- Neural Cache - cross-window KV caching (#318)
- Canon ACD (#312)
- BitNet b1.58 - ternary weights (#139, #126) - DEAD END
- Low-Rank Q factorization (#316, #215)
- Error Correction Table (#232, #108)
- PPM-C eval-time context mixer (#283)
- Paid prefix (#168) - 1.0238 bpb but likely disqualified
- MoE Token-Routed (#250, #224)
- SSM/LRU (#220)
- Linearized Neural Memory (#182)
- Content-Dependent SmearGate (#288) - doesn't beat static
- SwiGLU as relu^2 replacement (#373, #81)
- Memory Tokens (#352)
- Backout Connection (#339, #366)
- Gradient-Guided Quantization (#332)
- TrigramHash (#327)
- Hypernetwork approach (#336)
- Multi-Head Latent Attention (#354)

### Tier 5: Tooling & Infrastructure PRs
- ROCm support (#188)
- MLX sliding window eval (#233)
- Local GPU Docker workflow (#227)
- Autoresearch harnesses (#234, #66, #80, #344, #343)
- Community leaderboard tools (#158, Issue #87)
- TIPS.md documentation (#357)

## Key Negative Results

- QAT overhead exceeds recovery at int8 level (#145) - lost steps hurt more than quant gap
- SWA doesn't help int8 with default warmdown (#199)
- TTT hurts XSA+EMA models (#303) - but CONTRADICTED by #338 (alertcat made it work)
- int5 catastrophic for undertrained models (#238)
- SWA reverses quant gap (post-SWA int6 BPB < pre-quant BPB) (#238) - this is POSITIVE
- Error-guided TTT doesn't work (#296) - high-loss tokens are genuinely unpredictable
- Content-Dependent SmearGate doesn't beat static SmearGate (#288)
- Width > depth FAILS: 4x768 got 1.3043 (#185) - depth wins decisively
- Quantization error amplifies ~900x through 3 cycles of depth recurrence (#363)
- BitNet ternary: entire standard stack breaks (#367)
- QAT costs 8% of steps, EMA costs 32% of steps - throughput loss (#360)

## Learnings from Unscored / WIP PRs

### Promising Ideas Awaiting Compute
- #322 (romainsantoli-web): Full stack targeting sub-1.135 - 11L SmearGate + BigramHash + Causal TTT + Mixed Int5/Int6
- #235 (zeyuchenphd): 6-bit QAT + SP4096 + Layer Recurrence 5x2
- #277 (mohosy): XSA + TTT combined on full meta stack
- #291 (mohosy): 11L EMA + XSA + Int6 MLP3x pending compute
- #297 (davidpuertolas): Late STE QAT + full stack + SGD TTT

### Architecture Insights
- Depth recurrence works but quant error amplifies through loops (#363, #319, #325)
- 12 layers is viable: #76 hit 1.1433, #332 hit 1.1320 with Gradient-Guided Quant
- Int5 MLP compression funds extra layers
- Looped transformers best result: 1.1462 (#325) but explicitly "far from optimized"
- Hybrid depth-recurrent (#341) keeps precision-sensitive layers unique - may fix quant amplification

### Training Insights
- Warmdown matters: WARMDOWN_ITERS=1200 is broken at 600s wallclock (#104). Fix: 3000+
- Smaller batch = more steps = better: 524K > 786K (#236)
- Weight decay controls artifact size: aggressive WD reduces quant gap AND compressed size (#98)
- Late QAT (85% wallclock) avoids instability (#315, #286)
- Muon momentum 0.99 is consensus optimal
- Aggressive warmdown (entire run as decay) drops post-quant penalty from 0.014 to 0.005 (#365)

### Eval-Time Insights
- Sliding window stride=64 standard. Stride=32 marginal gain (#274, #331)
- TTT and XSA partially redundant (#303) but #338 contradicts this
- Neural Cache (#318) theoretically sound but unvalidated
- PPM-C context mixer (#283) ~0.015 BPB improvement at zero artifact cost
- Error Correction Tables (#232, #108) clever but likely rule-bending

## KEY FINDINGS (Latest)

### NEW SOTA: PR #374 by unnir (1.1246 bpb)
- "Tight SWA" - only average checkpoints from last ~600 steps (scale < 0.2), every 50 steps
- Shared VE128 - new technique
- Stack: 11L + Tight SWA + Shared VE128 + Partial RoPE + LN Scale + XSA4

### FA3 = 71% more steps (PR #369)
- 58ms/step with FA3 vs 99ms/step with SDPA
- THE COMPETITION IS NOW THROUGHPUT-LIMITED, NOT TECHNIQUE-LIMITED

### QAT + EMA hurt throughput (PR #360)
- QAT costs 8% of steps, EMA costs 32% of steps
- Systems optimizations that recover those steps would flip this equation

### TTT+XSA+EMA combo works (PR #338)
- alertcat got 1.1254 with all three combined

### Updated Meta Stack
- 11L 512d (or 12L with smart quant)
- XSA4 on last 4 layers
- EMA (0.997) or Tight SWA (scale < 0.2)
- Partial RoPE + LN Scale
- Int5 MLP / Int6 Attention mixed quant
- BigramHash (2048-12288 buckets)
- SmearGate
- Batch 524K
- Sliding window eval stride=64 (or 32)
- FlashAttention 3 (if available)

### Key Players
| Author | PRs | Best Score | Notes |
|--------|-----|------------|-------|
| unnir | #102, #135, #265, #374 | 1.1246 | Current SOTA. Tight SWA inventor. |
| jfprincz | #70, #164, #198, #287, #315 | 1.1248 | Serial SOTA holder. Methodical stacking. |
| alertcat | #219, #338 | 1.1254 | First TTT+XSA+EMA success. |
| saml212 | #61, #96, #114, #236, #332 | 1.1320 | 12L pioneer. Batch optimization finding. |
| timowhite88 | #254 | 1.1303 | FarnsworthEngine - TTT + full stack. |
| chris-buckley | #191, #286, #317 | 1.1442 | TTT + full stack. |
| baudrillardsgh0st | #170, #192, #194 | 1.1480 | Int6 QAT + SmearGate pioneer. |
| anthony-maio | #175, #376 | 1.1401 | Custom Kernel Pipeline - one of only systems-level entries. |

### Trend Analysis

Phase 1 (Mar 18): Low-hanging fruit. Baseline 1.2244. FP16 embed, longer sequences. Scores hit ~1.20.
Phase 2 (Mar 19): Quantization revolution. Int6 + zstd-22 + 3x MLP + sliding eval. Scores hit ~1.16.
Phase 3 (Mar 20): Convergence. SmearGate + BigramHash + OrthoInit became standard. Scores hit ~1.14.
Phase 4 (Mar 21): XSA + EMA + Partial RoPE + LN Scale. TTT re-emerges. Scores hit ~1.12.
Phase 5 (Mar 21 evening): THROUGHPUT IS THE BOTTLENECK. Recipe commoditized. Edge comes from systems optimization, eval tricks, or smart quant.

---

## Change Log

- 2026-03-22 01:00 ET: Added author classification column (HS/UG/Grad/Pro/Sr) to all tables.
- 2026-03-22 00:30 ET: Rebuilt with FULL 253-PR table + restored all analysis sections.
- 2026-03-22 00:10 ET: FULL 253-PR sweep. Every single entry with scores cataloged. 174 scored, 79 unscored.
- 2026-03-21 18:57 ET: Fixed confirmed leaderboard table.
- 2026-03-21 18:40 ET: NEW SOTA #374 (1.1246 unnir). FA3 = 71% more steps. 252 open PRs.
- 2026-03-21 05:00 ET: Full 214-PR sweep.
- 2026-03-21 04:52 ET: Initial baseline snapshot.
