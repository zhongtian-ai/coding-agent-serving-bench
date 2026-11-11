# 2026-11-11 · GLM-5.3-Flash · official SGLang recipe vs optimized build · 8 GPUs per setup

Two serving setups of the same model on two identical 8-GPU nodes, measured with this repository's corpus and
script at concurrency 16, 32 and 64 (warm-up 60 s, measured 180 s per level). Both runs happened at the same time,
one per node; the client ran on each node itself, inside a throw-away container from the server's own image
(identical Python 3.12.16 / aiohttp 3.14.5, no network between client and server).

## Setups

| | official-sglang | optimized-zt |
|---|---|---|
| Hardware | 8 GPUs, `nvidia-smi` name **NVIDIA L20X**, 141 GB each; 224 CPU cores | identical node model and spec |
| Engine build | SGLang `nightly-dev-20261106-858073e4` | same build + our patch layer ([glm-flash-h200](https://github.com/zhongtian-ai/glm-flash-h200), image `h200-20261110`) |
| Weights | `zai-org/GLM-5.3-Flash` (official FP8) | same |
| Parallelism | TP8 + EP8 | TP8 + EP8 |
| Speculative decoding | off (cookbook recipe) | MTP (EAGLE) 3 steps / top-k 1 / 4 draft tokens |
| MoE kernel | default | MegaMoE fused kernel (`TIER=p1`, `MOE=mega`) |
| KV cache | BF16, no host-memory tier | BF16, no host-memory tier |
| Max running requests | SGLang automatic | 48 (SGLang's automatic value with speculative decoding on) |

## Result

All integrity checks PASS on every level for both setups: no other traffic on either server (server-side running +
queued requests never exceeded ours; idle before and after), 100% of responses had exactly the requested output
length, canary accuracy 1.0 under load (= idle), temperature-0 fingerprints identical before and after.

| Concurrency | Output tok/s, official → optimized | Per-user tok/s p50 | TTFT p50 / p99 (ms) | TPOT p50 / p99 (ms) | End-to-end p50 (s) |
|---:|---|---|---|---|---|
| 16 | 1,037 → **1,780 (1.72×)** | 68 → 120 | 124 / 294 → 135 / 300 | 14.6 / 16.9 → **8.3 / 12.3** | 3.2 → 2.0 |
| 32 | 1,546 → **2,540 (1.64×)** | 51 → 86 | 132 / 339 → 152 / 343 | 19.7 / 24.0 → **11.6 / 17.3** | 4.4 → 2.7 |
| 64 | 2,148 → **2,954 (1.38×)** | 36 → 66 | 144 / 402 → **1,703 / 2,298** | 28.1 / 33.1 → **15.2 / 22.3** | 6.1 → 5.1 |

Single user on an idle server: 139 → 242 tok/s. Prompt tokens served from the prefix cache: 92–94% for both
(shared system prompt + growing session prefix). Full tables: [`compare.md`](compare.md).

## Read this before quoting the numbers

- **Concurrency 64, optimized setup: time to first token is 1.7 s.** With speculative decoding on, SGLang
  automatically limits this server to 48 requests running at once, so 16 of the 64 requests wait in the server queue
  and the wait is part of TTFT. Throughput and per-token latency are still better. This deployment was configured for
  a ≤ 32-agent load; for 64+ concurrent agents the same image has a tier with a higher limit (`TIER=f2`, 96 running
  requests), which was **not** measured in this run.
- Streaming gap p99 (ITL) at concurrency 16 is higher for the optimized setup (120 vs 86 ms): with speculative
  decoding a streamed chunk carries several tokens, and prompt reads of other requests occasionally delay a chunk.
  TPOT p99, which accounts for tokens per chunk, is lower.
- Both setups replay the same session sequence; the faster one gets further through it in 3 minutes, so the
  measured windows contain a slightly different request mix (average prompt 19–24K tokens for both).
- 3-minute windows: medians and throughput are stable to ~1–2%; p99 values can move ±25% between runs.

## Reproduce

```bash
python3 bench/run.py --url http://<server>:30000 --model zai-org/GLM-5.3-Flash --label <name> --out results/<name> \
    --concurrency 16,32,64 --warmup 60 --duration 180
# what we ran, on each node:
bash scripts/run_podman_host.sh glm <name> --concurrency 16,32,64 --warmup 60 --duration 180
```
