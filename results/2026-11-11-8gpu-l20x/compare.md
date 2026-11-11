| Setup | Corpus sha256 (first 12) | Idle before / after | Fingerprint stable | Single-user tok/s (idle) |
|---|---|---|---|---|
| official-sglang | `6e93e8a5f3f6` | PASS / PASS | True | 138.9 |
| optimized-zt | `6e93e8a5f3f6` | PASS / PASS | True | 241.7 |

**Output tokens/s (whole server)** — higher is better

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 1,037 | 1,780 (1.72×) |
| 32 | 1,546 | 2,540 (1.64×) |
| 64 | 2,148 | 2,954 (1.38×) |

**Per-user output speed p50 (tok/s)** — higher is better

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 68.3 | 120.4 (1.76×) |
| 32 | 50.7 | 85.9 (1.69×) |
| 64 | 35.6 | 65.7 (1.85×) |

**TTFT p50 (ms)** — lower is better

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 124 | 135 (1.08×) |
| 32 | 132 | 152 (1.15×) |
| 64 | 144 | 1,703 (11.86×) |

**TTFT p99 (ms)** — lower is better

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 294 | 300 (1.02×) |
| 32 | 339 | 343 (1.01×) |
| 64 | 402 | 2,298 (5.72×) |

**TPOT p50 (ms)** — lower is better

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 14.6 | 8.3 (0.57×) |
| 32 | 19.7 | 11.6 (0.59×) |
| 64 | 28.1 | 15.2 (0.54×) |

**TPOT p99 (ms)** — lower is better

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 16.9 | 12.3 (0.73×) |
| 32 | 24.0 | 17.3 (0.72×) |
| 64 | 33.1 | 22.3 (0.67×) |

**End-to-end p50 (s)** — lower is better

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 3.2 | 2.0 (0.62×) |
| 32 | 4.4 | 2.7 (0.63×) |
| 64 | 6.1 | 5.1 (0.83×) |

**Completed requests** — higher is better

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 606 | 1,005 (1.66×) |
| 32 | 876 | 1,449 (1.65×) |
| 64 | 1,246 | 1,691 (1.36×) |

**Prompt tokens served from cache**

| Concurrency | official-sglang | optimized-zt |
|---:|---:|---:|
| 16 | 94% | 92% |
| 32 | 92% | 93% |
| 64 | 92% | 92% |

**Integrity checks per level** (exclusive = no other traffic on the server; fixed_len = identical output lengths; canary = answer accuracy under load)

| Setup | Concurrency | exclusive | max extra requests seen | fixed_len | canary accuracy | prefill |
|---|---:|---|---:|---|---|---|
| official-sglang | 16 | PASS | 0 | PASS (1.0) | 1.0 (n=15) | PASS |
| official-sglang | 32 | PASS | 0 | PASS (1.0) | 1.0 (n=18) | PASS |
| official-sglang | 64 | PASS | 0 | PASS (1.0) | 1.0 (n=34) | PASS |
| optimized-zt | 16 | PASS | 0 | PASS (1.0) | 1.0 (n=30) | PASS |
| optimized-zt | 32 | PASS | 0 | PASS (1.0) | 1.0 (n=36) | PASS |
| optimized-zt | 64 | PASS | 0 | PASS (1.0) | 1.0 (n=42) | PASS |
