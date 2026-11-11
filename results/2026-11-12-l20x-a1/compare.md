| Setup | Corpus sha256 (first 12) | Idle before / after | Fingerprint stable | Single-user tok/s (idle) |
|---|---|---|---|---|
| official-sglang | `6e93e8a5f3f6` | PASS / PASS | True | 138.9 |
| optimized-zt | `6e93e8a5f3f6` | PASS / PASS | True | 241.7 |
| a1-l20x | `6e93e8a5f3f6` | PASS / PASS | True | 283.2 |
| official-l20x-https | `6e93e8a5f3f6` | PASS / PASS | True | 129.9 |
| a1-l20x-https | `6e93e8a5f3f6` | PASS / PASS | True | 293.1 |

**Output tokens/s (whole server)** — higher is better

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 1,037 | 1,780 (1.72×) | 1,786 (1.72×) | 972 (0.94×) | 1,619 (1.56×) |
| 32 | 1,546 | 2,540 (1.64×) | 2,553 (1.65×) | 1,469 (0.95×) | 2,418 (1.56×) |
| 64 | 2,148 | 2,954 (1.38×) | 3,357 (1.56×) | 2,112 (0.98×) | 3,297 (1.53×) |

**Per-user output speed p50 (tok/s)** — higher is better

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 68.3 | 120.4 (1.76×) | 121.5 (1.78×) | 70.9 (1.04×) | 130.2 (1.91×) |
| 32 | 50.7 | 85.9 (1.69×) | 86.0 (1.70×) | 52.5 (1.04×) | 92.7 (1.83×) |
| 64 | 35.6 | 65.7 (1.85×) | 57.1 (1.60×) | 36.9 (1.04×) | 61.2 (1.72×) |

**TTFT p50 (ms)** — lower is better

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 124 | 135 (1.08×) | 136 (1.09×) | 561 (4.51×) | 580 (4.66×) |
| 32 | 132 | 152 (1.15×) | 152 (1.15×) | 582 (4.41×) | 604 (4.58×) |
| 64 | 144 | 1,703 (11.86×) | 184 (1.28×) | 603 (4.20×) | 650 (4.53×) |

**TTFT p99 (ms)** — lower is better

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 294 | 300 (1.02×) | 278 (0.95×) | 795 (2.70×) | 757 (2.58×) |
| 32 | 339 | 343 (1.01×) | 329 (0.97×) | 804 (2.37×) | 861 (2.54×) |
| 64 | 402 | 2,298 (5.72×) | 443 (1.10×) | 900 (2.24×) | 1,054 (2.62×) |

**TPOT p50 (ms)** — lower is better

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 14.6 | 8.3 (0.57×) | 8.2 (0.56×) | 14.1 (0.97×) | 7.7 (0.53×) |
| 32 | 19.7 | 11.6 (0.59×) | 11.6 (0.59×) | 19.1 (0.97×) | 10.8 (0.55×) |
| 64 | 28.1 | 15.2 (0.54×) | 17.5 (0.62×) | 27.1 (0.96×) | 16.3 (0.58×) |

**TPOT p99 (ms)** — lower is better

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 16.9 | 12.3 (0.73×) | 12.2 (0.72×) | 16.7 (0.99×) | 11.4 (0.67×) |
| 32 | 24.0 | 17.3 (0.72×) | 16.9 (0.70×) | 22.4 (0.93×) | 15.4 (0.64×) |
| 64 | 33.1 | 22.3 (0.67×) | 26.2 (0.79×) | 32.2 (0.97×) | 25.1 (0.76×) |

**End-to-end p50 (s)** — lower is better

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 3.2 | 2.0 (0.62×) | 1.9 (0.61×) | 3.5 (1.10×) | 2.3 (0.71×) |
| 32 | 4.4 | 2.7 (0.63×) | 2.7 (0.62×) | 4.7 (1.08×) | 2.9 (0.67×) |
| 64 | 6.1 | 5.1 (0.83×) | 4.0 (0.65×) | 6.4 (1.06×) | 4.2 (0.70×) |

**Completed requests** — higher is better

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 606 | 1,005 (1.66×) | 1,008 (1.66×) | 577 (0.95×) | 918 (1.51×) |
| 32 | 876 | 1,449 (1.65×) | 1,461 (1.67×) | 840 (0.96×) | 1,391 (1.59×) |
| 64 | 1,246 | 1,691 (1.36×) | 1,952 (1.57×) | 1,220 (0.98×) | 1,913 (1.54×) |

**Prompt tokens served from cache**

| Concurrency | official-sglang | optimized-zt | a1-l20x | official-l20x-https | a1-l20x-https |
|---:|---:|---:|---:|---:|---:|
| 16 | 94% | 92% | 92% | 94% | 92% |
| 32 | 92% | 93% | 93% | 92% | 93% |
| 64 | 92% | 92% | 92% | 92% | 92% |

**Integrity checks per level** (exclusive = no other traffic on the server; fixed_len = identical output lengths; canary = answer accuracy under load)

| Setup | Concurrency | exclusive | max extra requests seen | fixed_len | canary accuracy | prefill |
|---|---:|---|---:|---|---|---|
| official-sglang | 16 | PASS | 0 | PASS (1.0) | 1.0 (n=15) | PASS |
| official-sglang | 32 | PASS | 0 | PASS (1.0) | 1.0 (n=18) | PASS |
| official-sglang | 64 | PASS | 0 | PASS (1.0) | 1.0 (n=34) | PASS |
| optimized-zt | 16 | PASS | 0 | PASS (1.0) | 1.0 (n=30) | PASS |
| optimized-zt | 32 | PASS | 0 | PASS (1.0) | 1.0 (n=36) | PASS |
| optimized-zt | 64 | PASS | 0 | PASS (1.0) | 1.0 (n=42) | PASS |
| a1-l20x | 16 | PASS | 0 | PASS (1.0) | 1.0 (n=30) | PASS |
| a1-l20x | 32 | PASS | 0 | PASS (1.0) | 1.0 (n=36) | PASS |
| a1-l20x | 64 | PASS | 0 | PASS (1.0) | 1.0 (n=64) | PASS |
| official-l20x-https | 16 | PASS | 0 | PASS (1.0) | 1.0 (n=14) | PASS |
| official-l20x-https | 32 | PASS | 0 | PASS (1.0) | 1.0 (n=18) | PASS |
| official-l20x-https | 64 | PASS | 0 | PASS (1.0) | 1.0 (n=41) | PASS |
| a1-l20x-https | 16 | PASS | 0 | PASS (1.0) | 1.0 (n=23) | PASS |
| a1-l20x-https | 32 | PASS | 0 | PASS (1.0) | 1.0 (n=41) | PASS |
| a1-l20x-https | 64 | PASS | 0 | PASS (1.0) | 1.0 (n=63) | PASS |
