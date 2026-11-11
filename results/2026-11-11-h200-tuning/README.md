# 2026-11-11 · GLM-5.3-Flash · tuning the optimized build for this workload · 8× H200

After the [side-by-side run](../2026-11-11-8gpu-l20x/README.md), the optimized setup's one weak spot was concurrency 64
(first token 1.7 s). We tuned its launch settings for this corpus on one 8× H200 node (141 GB each), one configuration
at a time, same script and settings as before (warm-up 60 s, measured 180 s, concurrency 16 / 32 / 64; client on the
node itself inside a container from the server's image). Each configuration is a fresh server start.

**B0 reproduces the earlier optimized-zt run within 1%** (1,780 / 2,532 / 2,946 tok/s here vs 1,780 / 2,540 / 2,954), so
the two 8-GPU node types behave the same on this workload and the tuning should carry over. That needs to be confirmed on
the other hardware, which is what the next run is for.

## Configurations

All use the image `glm-flash-sglang` (SGLang `858073e4` + patch layer), MegaMoE, MTP speculative decoding, TP8 + EP8.

| Label | Settings | What it tests |
|---|---|---|
| B0 | `TIER=p1` | the setup measured in the side-by-side run (running cap 48, chosen by SGLang automatically when MTP is on) |
| C1 | p1 + `--max-running-requests 64 --cuda-graph-max-bs-decode 64` | let all 64 agents run instead of queueing 16 |
| C2 | C1 + 2 speculative steps / 3 draft tokens (instead of 3 / 4) | shorter drafts at high batch |
| C3 | `TIER=f2 HICACHE=0`: FP8 KV cache, cap 96, TileLang prefill | the high-concurrency tier |
| C4 | `TIER=f1` (adds host-RAM KV tier) + cap 64 | a second KV tier in host memory |
| D1 | C1 + 4 speculative steps / 5 draft tokens | longer drafts |
| D2 | C1 + `--chunked-prefill-size 16384` (default 8192) | fewer prefill chunks |
| **A1** | **`TIER=a1`** = D2, packaged as a new tier in the launcher | confirmation run of the release candidate |

## Result

All integrity checks PASS on every level of every run (no other traffic, exact output lengths, canary accuracy 1.0,
fingerprints stable). Full tables: [`compare.md`](compare.md).

| Concurrency | Output tok/s B0 → A1 | TTFT p50 (ms) | TTFT p99 (ms) | TPOT p50 (ms) | End-to-end p50 (s) |
|---:|---|---|---|---|---|
| 16 | 1,780 → 1,779 (1.00×) | 127 → 126 | 272 → 257 | 8.3 → 8.3 | 2.0 → 2.0 |
| 32 | 2,532 → 2,563 (1.01×) | 142 → 141 | 408 → 357 | 11.7 → 11.5 | 2.7 → 2.6 |
| 64 | 2,946 → **3,390 (1.15×)** | 1,676 → **172** | 2,868 → **434** | 15.3 → 17.4 | 5.1 → **3.9** |

Output tokens/s, all configurations:

| Concurrency | B0 | C1 | C2 | C3 | C4 | D1 | D2 | A1 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 1,780 | 1,764 | 1,630 | 1,675 | 1,690 | 1,815 | 1,759 | 1,779 |
| 32 | 2,532 | 2,521 | 2,348 | 2,309 | 2,426 | 2,484 | 2,530 | 2,563 |
| 64 | 2,946 | 3,278 | 3,123 | 2,935 | 3,128 | 3,290 | 3,355 | 3,390 |

What we learned:

- **The running-request cap is the whole story at 64.** With MTP on, SGLang picks a cap of 48; raising it to 64 (C1)
  gives +11% throughput and removes the 1.5 s queueing from first-token time. Per-token time goes up (15 → 17-18 ms)
  because 64 requests now decode together instead of 48, but every request finishes sooner (end-to-end 5.1 → 4.1 s).
- Larger prefill chunks (D2) add a little at 64 (+2%); A1 repeats D2 within 1%.
- Host-RAM KV tier (C4): −4–5%. The KV cache for 64 sessions fits in GPU memory; the extra tier is pure overhead here.
- FP8 KV + cap 96 (C3, `f2`): −5–10% vs C1. Built for 128+ sessions; at ≤ 64 the FP8 conversion and TileLang prefill cost more than the capacity buys.
- 2 speculative steps (C2): −5–8%. 4 steps (D1): within noise of 3 → kept 3.
- At 16 and 32 nothing beat B0 by more than noise (±2%): the earlier setup was already right for those loads.

## Reproduce

```bash
# server (image from https://github.com/zhongtian-ai/glm-flash-h200, launcher with TIER=a1)
docker run ... -e TIER=a1 <image> /opt/glm-flash/launch.sh
# or, with an older image of the same build:
docker run ... -e TIER=p1 <image> /opt/glm-flash/launch.sh --max-running-requests 64 --cuda-graph-max-bs-decode 64 --chunked-prefill-size 16384
# client
bash scripts/run_podman_host.sh <container> <label> --concurrency 16,32,64 --warmup 60 --duration 180
```

Each run directory holds `summary.json`, per-request and canary records, `server_info.json` (the server's full
effective settings from `/get_server_info`) and `SHA256SUMS`.
