# coding-agent-serving-bench

A small, reproducible load test for comparing LLM serving setups **fairly** on a coding-agent workload.
Point it at any OpenAI-compatible endpoint (SGLang, vLLM, TensorRT-LLM, a gateway), get throughput and latency at
several concurrency levels, plus integrity checks that tell you whether the comparison was actually fair.

Everything needed to reproduce a run is in this repository: the request corpus (`corpus/coding_v1.jsonl.gz`,
sha256 `6e93e8a5f3f6…`), the load generator, and the comparison script. Two people running it against the same
server get the same numbers within noise.

## Quick start

```bash
pip install aiohttp            # the only dependency (Python >= 3.9)
python3 bench/run.py --url http://SERVER:30000 --model zai-org/GLM-5.3-Flash --label setup-a \
    --out results/setup-a --concurrency 16,32,64 --warmup 60 --duration 180
python3 bench/run.py --url http://OTHER:30000  --model zai-org/GLM-5.3-Flash --label setup-b \
    --out results/setup-b --concurrency 16,32,64 --warmup 60 --duration 180
python3 bench/compare.py results/setup-a results/setup-b --md results/compare.md
```

To also verify that **no one else was using the server during the run** (recommended), give the script the
server's log stream. On a host running the server in podman/docker:

```bash
# runs the client inside a throw-away container from the server's own image (same Python everywhere, no network hop)
bash scripts/run_podman_host.sh <server-container-name> setup-a --concurrency 16,32,64 --warmup 60 --duration 180
# or, generically:
python3 bench/run.py ... --server-log-cmd "docker logs -f --since 1s <container>"
```

An API key, if needed, is read from an environment variable you name with `--api-key-env MY_KEY_VAR`; it is never
written to results.

## The workload

`corpus/coding_v1.jsonl.gz`: 120 coding-agent sessions, 2,633 requests (`bench/gen_corpus.py`, seed 20261111).

- Each session is an agent working on one task in a Python repository (fix a failing test, add type hints, refactor,
  find a performance bug…): a shared agent system prompt and 6 tool schemas (read_file, grep_code, list_dir,
  edit_file, run_command, git_diff), the user's task, then alternating tool calls and tool results — file reads with
  line numbers, grep hits, pytest output with tracebacks, diffs, directory listings. The code is real source code
  (Python standard library), not lorem ipsum.
- Request *k* of a session is the conversation up to step *k*, so consecutive requests share a growing prefix — the
  defining property of agent traffic. Prompt length p10 / p50 / p90 / max ≈ 6K / 19K / 41K / 64K tokens.
  Output length per request p10 / p50 / p90 ≈ 95 / 217 / 676 tokens (short tool calls, longer edits and summaries).
- Load model: **closed loop**. At concurrency N, N agents each play sessions turn by turn, sending the next request
  as soon as the previous one finishes, so exactly N requests are always in flight. No think time (stress test).

## Fairness rules built into the script

| Rule | How |
|---|---|
| Same work for every setup | Same corpus (sha256 recorded), same session order (seeded), same sampling (temperature 0.6, top-p 0.95), thinking off by default |
| Identical output lengths | Each request asks for a fixed number of tokens with `ignore_eos`; tool schemas are sent but `tool_choice: none`, so no server can end a response early at a tool call. Checked: `completion_tokens == requested` |
| No cross-run caching tricks | Every session instance starts with a fresh random repository path, so nothing can be answered from a cache built by an earlier run or by knowing the public corpus. Within-session prefix caching (which real agents get) still works |
| Steady state only | `--warmup` seconds are not measured; throughput counts only tokens streamed inside the measurement window |
| No benchmark fingerprint | Generic client headers, natural-looking prompts, canary questions look like normal agent turns |

## Integrity checks (in `integrity.json` / `summary.json`, and in the compare table)

| Check | Catches | Pass when |
|---|---|---|
| **exclusive** | Other people's traffic on the server during the test (a shared or "busy" server makes one setup look slower; an idle reference makes it look faster) | Server idle for 20 s before and 15 s after; during the run the server's own count of running + queued requests (from its log) never exceeds our in-flight count by ≥ 2 in more than 1% of log lines, and its prompt-token count matches ours. SGLang and vLLM log formats are parsed |
| **fixed_len** | A server truncating, ignoring `ignore_eos`, or inflating token counts | ≥ 99% of responses have exactly the requested length; characters per token in a plausible range |
| **canary** | Quality dropping under load (or a different model behind the endpoint when busy) | ~2% of requests are easy questions with one computable answer, asked in the same agent context at temperature 0; accuracy under load ≥ accuracy measured idle before the run |
| **fingerprint** | The model changing during the run | Temperature-0 answers to three fixed prompts are identical before and after |
| **prefill** | Responses replayed from a cache | No request reports an uncached prompt read faster than 1M tokens/s |

## Metrics

Output tokens/s for the whole server (main throughput number) · per-user output speed · TTFT (time to first
streamed token) p50/p90/p95/p99 · TPOT (time per output token after the first) · ITL (gap between streamed chunks;
with speculative decoding one chunk can carry several tokens) · end-to-end latency · requests/s · fraction of prompt
tokens served from the server's prefix cache (as reported by the server).

## Results

| Date | What | Link |
|---|---|---|
| 2026-11-11 | GLM-5.3-Flash, official SGLang recipe vs optimized build, 8 GPUs each, concurrency 16 / 32 / 64 — optimized output throughput 1.72× / 1.64× / 1.38×, all integrity checks PASS | [`results/2026-11-11-8gpu-l20x/`](results/2026-11-11-8gpu-l20x/README.md) |

Add your own run as `results/<date>-<hardware>/<setup>/` (open a pull request); the compare script works across
anyone's runs as long as the corpus sha256 matches. Every run directory contains `summary.json` (metrics, integrity checks, manifest with
corpus and script sha256, client versions, start/end time), per-request records and `SHA256SUMS`.

## License

Code: Apache-2.0. The corpus contains excerpts of CPython standard-library source code (PSF License 2.0).
