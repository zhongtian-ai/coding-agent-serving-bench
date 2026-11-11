# 2026-11-12 · GLM-5.3-Flash · `TIER=a1` (running cap 64) confirmed on 8× L20X

The [H200 tuning run](https://github.com/zhongtian-ai/coding-agent-serving-bench/pull/1) found one change that matters at
64 concurrent agents: raise the running-request cap from 48 (chosen by SGLang automatically when MTP is on) to 64. That
became `TIER=a1` in [glm-flash-h200](https://github.com/zhongtian-ai/glm-flash-h200) (PR #2, merged). This run checks
that it carries over to the L20X node of the [side-by-side run](../2026-11-11-8gpu-l20x/README.md).

**Same node, same image, same script, same settings as `optimized-zt` there; only the launch flags differ.**

| | optimized-zt (2026-11-11) | a1-l20x (this run) |
|---|---|---|
| Hardware | 8× NVIDIA L20X 141 GB | same node |
| Image | `glm-flash:h200-20261110` (SGLang `858073e4` + patch layer) | same |
| Launch | `TIER=p1 MOE=mega` | `TIER=p1 MOE=mega` + `--max-running-requests 64 --cuda-graph-max-bs-decode 64 --chunked-prefill-size 16384` (= `TIER=a1`; this image predates the tier) |
| Effective settings | `max_running_requests` 48, prefill chunk 8192 | `max_running_requests` 64, prefill chunk 16384 (`server_info.json`) |
| Client | `scripts/run_podman_host.sh`, warm-up 60 s, measured 180 s, c16 / 32 / 64 | same |

## Result

All integrity checks PASS on every level: exclusive, fixed length, canary accuracy, prefill, plus fingerprint stable and idle before and after.

| Concurrency | Output tok/s: official → p1 → **a1** | TTFT p50 / p99 (ms), p1 → **a1** | TPOT p50 (ms), p1 → a1 | End-to-end p50 (s), p1 → a1 |
|---:|---|---|---|---|
| 16 | 1,037 → 1,780 → **1,786** | 135 / 300 → **136 / 278** | 8.3 → 8.2 | 2.0 → 1.9 |
| 32 | 1,546 → 2,540 → **2,553** | 152 / 343 → **152 / 329** | 11.6 → 11.6 | 2.7 → 2.7 |
| 64 | 2,148 → 2,954 → **3,357 (+14% vs p1, 1.56× official)** | 1,703 / 2,298 → **184 / 443** | 15.2 → 17.5 | 5.1 → **4.0** |

- At 64 the 16 requests that used to wait in the server queue now run, so time to first token drops from 1.7 s to 0.18 s,
  which is close to the official recipe's 0.14 s, and throughput rises 14%. On 8× H200 the same change gave 2,946 → 3,390 (+15%).
- Per-token time at 64 rises from 15.2 to 17.5 ms because 64 instead of 48 requests decode together. Every request
  still finishes sooner (end-to-end p50 5.1 → 4.0 s).
- 16 and 32 are unchanged within noise.
- Single user on an idle server: 283 tok/s. This is one probe and was not repeated; the p1 run measured 242.
- The first burst after a server restart is slow, about 15 s time to first token, while DeepGEMM / Triton kernels JIT-compile for the new
  batch sizes. Warm the server up before measuring; the script's 60 s warm-up covers this.

## Same test over the public HTTPS endpoint

Partners reach the deployment through `https://glm-flash.aitist.ai`. That path goes through Cloudflare, then a gateway, then an ssh forward to the server, and the gateway pins the backend by model name: `glm-zt` is the optimized build, `glm-official` is the official one. We ran the same script that way too, from a workstation on the public internet:

```bash
python3 bench/run.py --url https://glm-flash.aitist.ai --model glm-zt --label a1-l20x-https --out results/a1-l20x-https \
    --concurrency 16,32,64 --warmup 60 --duration 180 --server-log-cmd "<stream the server container's log>"
```

The server log was streamed back for the exclusivity check. All integrity checks PASS on every level, with 0 failed requests.

| Concurrency | Output tok/s: official → **a1** (HTTPS) | TTFT p50 / p99 (ms): official → **a1** | a1: HTTPS vs on-node |
|---:|---|---|---|
| 16 | 972 → **1,619 (1.67×)** | 561 / 795 → **580 / 757** | −9% throughput, +0.44 s TTFT |
| 32 | 1,469 → **2,418 (1.65×)** | 582 / 804 → **604 / 861** | −5%, +0.45 s |
| 64 | 2,112 → **3,297 (1.56×)** | 603 / 900 → **650 / 1,054** | −2%, +0.47 s |

The public path adds a flat ~0.45 s to time to first token for both setups, from the network round trip and the gateway. It does not grow with concurrency. Throughput is within 2–9% of the on-node numbers, and the optimized/official ratio is the same as on-node. In these two runs `client.host` is replaced by a description, `server_log_cmd` is described rather than quoted, and `SHA256SUMS` is regenerated.

Full tables: [`compare.md`](compare.md). The client hostname in `summary.json` was replaced by a description, as in the earlier
L20X run, and `SHA256SUMS` was regenerated after that edit. The raw server log is not kept, by design of `run_podman_host.sh`.
