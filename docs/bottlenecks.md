User: I added more runs to these results but I still don't understand the throughput plateau around 15 total workers. It all of a sudden jumps up at 19. This is quite repeatable.

GitHub Copilot: Let me analyze the data more carefully and look at the BOOM architecture to understand what's causing these performance tiers.

Read [](file:///home/pbachant/calkit/boom-paper/results/boom.csv)

Read [](file:///home/pbachant/calkit/boom-paper/boom/ARCHITECTURE.md)

Searched for text `partition|n_partitions|num_partitions` (`boom-paper` · `boom/**`), 20 results

Searched for regex `n_alert_workers\|n_enrichment_workers\|n_filter_workers\|num_workers` (`boom-paper` · `boom/config.yaml`), no results

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/enrichment/babamul.rs#575-575), lines 575 to 640

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/kafka/base.rs#1-1), lines 1 to 100

Read [](file:///home/pbachant/calkit/boom-paper/boom/src)

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/kafka/ztf.rs#1-1), lines 1 to 160

Searched for regex `Redis|redis|queue|ZTF_alerts_packets` (`boom-paper` · `boom/src/**`), 30 results

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/compose.yaml#1-1), lines 1 to 130

Searched for regex `BLPOP|BRPOP|RPUSH|LPUSH|enrich|filter|queue|packets_queue` (`boom-paper` · `boom/src/kafka/base.rs`), 20 results

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/bin/kafka_consumer.rs#1-1), lines 1 to 120

Searched for regex `alert_worker|n_alert_workers|n_enrichment|n_filter` (`boom-paper` · `boom/src/**`), 20 results

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/compose.yaml#130-130), lines 130 to 150

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/compose.yaml#150-150), lines 150 to 172

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/bin/scheduler.rs#1-1), lines 1 to 120

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/config.yaml)

Searched for regex `run_alert_worker|input_queue|output_queue|packets_queue|enrichment_queue` (`boom-paper` · `boom/src/alert/**`), 20 results

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/alert/base.rs#1-1), lines 1 to 100

Searched for regex `batch|chunk|BATCH|bulk_write|insert_many|CHUNK` (`boom-paper` · `boom/src/alert/base.rs`), no results

Searched for regex `batch|chunk|BATCH|bulk_write|insert_many|CHUNK|BLPOP|BRPOP` (`boom-paper` · `boom/src/enrichment/base.rs`), 13 results

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/enrichment/base.rs)

Searched for regex `rpop|lpush|RPOP|BRPOP|1000|batch_size|BATCH_SIZE` (`boom-paper` · `boom/src/alert/base.rs`), 7 results

Searched for regex `rpop|RPOP|batch|1000|candid|input_queue|output_queue|kafka|partition` (`boom-paper` · `boom/src/filter/**`), 20 results

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/filter/base.rs#1-1), lines 1 to 250

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/filter/base.rs#250-250), lines 250 to 500

Searched for regex `run_filter_worker|rpop|NonZero|loop|queue` (`boom-paper` · `boom/src/filter/base.rs`), 20 results

Searched for regex `limit|n_alerts|count|total|20250311|num|N_ALERTS` (`boom-paper` · `boom/tests/throughput/**`), 20 results

Searched for files matching `boom-paper` · `boom/tests/throughput/**`, 7 matches

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/_run.sh#1-1), lines 1 to 200

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/run.py)

Searched for regex `run_filter_worker|loop|rpop|output|kafka|topic|babamul` (`boom-paper` · `boom/src/filter/base.rs`), 20 results

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/enrichment/babamul.rs#1-1), lines 1 to 100

Read [](file:///home/pbachant/calkit/boom-paper/boom/src/filter/base.rs#820-820), lines 820 to 1000

Searched for regex `output_topic|topic_name|n_filters|filters|babamul|pipeline|aggregate|mongodb` (`boom-paper` · `boom/src/filter/**`), 20 results

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/mongo-init.sh)

Let me look at the log files from the specific runs that show the jump, to see where time is actually spent.

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D11-nf%3D3)

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D12-nf%3D3)

Searched for regex `enrichment|alert|filter|worker|processed|batch|received|ingested|classified` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/scheduler.log`), 30 results

Searched for regex `enrichment|alert|filter|worker|processed|batch|received|ingested|classified` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), 30 results

Let me look at the end of the scheduler logs and also the _run.sh output to see when each stage completes.

Searched for regex `received first message|Consumer` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/consumer.log`), 20 results

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D11-nf%3D3/scheduler.log#1-1), lines 1 to 4

Let me look at the _run.sh output logs which contain the stage timings, and find the specific "Consumer received first message" line.

Searched for regex `first message|continuing` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/consumer.log`), 2 results

Searched for regex `first message|continuing` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/consumer.log`), 2 results

Searched for regex `passed filter|filter.*passed|batch.*processed|alerts.*processed` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/scheduler.log`), 15 results

Searched for regex `passed filter|filter.*passed|batch.*processed|alerts.*processed` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), 15 results

Let me look at the last few lines of the scheduler logs to find stage completion times.

Searched for regex `15:35:0[56789]|15:35:1[01234]` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/scheduler.log`), 13 results

Searched for regex `21:23:0[56789]|21:23:0[5678]` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), 20 results

Searched for regex `15:35:0[5678]|15:35:1[01]` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/scheduler.log`), 1 result

Searched for regex `passed filter` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/scheduler.log`), 5 results

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D11-nf%3D3/scheduler.log#3520-3520), lines 3520 to 3541

Let me look at the middle portion of the ne=11 run to understand batch sizes through the run:

Searched for regex `passed filter|enqueued.*to filter|filter queue|ZTF_alerts_filter` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/scheduler.log`), 30 results

Compacted conversationThe grep hit its 30-match limit starting from the beginning. Let me look at the middle of the ne=11 scheduler log to understand what filter workers are doing between the start and end:

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D11-nf%3D3/scheduler.log#1760-1760), lines 1760 to 1820

Very revealing! The filter workers at t=9s are getting sub-1000 batches (477, 535, 598) and enrichment workers output tiny batches (26, 57, 64, 277). Let me check the ne=12 run at the same point in time to compare batch sizes:

Searched for regex `average_rate` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), 5 results

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D12-nf%3D3/scheduler.log#1948-1948), lines 1948 to 2020

Excellent! The filter batch sizes match the key difference: ne=12 filter batches are 784-838 at t=9s vs ne=11's 477-598. Let me check what happens mid-run in ne=12 to see if batches grow to full 1000:

Searched for regex `21:22:5[23].*passed filter` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), 15 results

At t=20s in the ne=12 run, all filter workers are getting full **1000-alert** batches — maximum capacity. Now let me check the ne=11 run at the same point in time:

Searched for regex `15:34:3[56].*passed filter` (`boom-paper` · `logs/boom-na=4-ne=11-nf=3/scheduler.log`), 15 results

Critical finding! At t=20s, ne=12 shows all **1000-alert** full batches, while ne=11 shows mixed 591/533/1000. Let me check what's in the ne=12 log's last few lines to understand the end condition:

Searched for text `scheduler.log` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3`), no results

Searched for files matching `**/logs/boom-na=4-ne=12-nf=3/*.log`, no matches

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D12-nf%3D3)

Searched for text `pipeline complete` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), no results

Searched for text `pipeline complete` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), no results

Searched for regex `21:23:0[89]|21:23:1` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), no results

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D12-nf%3D3/scheduler.log#1-1), lines 1 to 3

Searched for regex `Successfully sent|passed filter|heartbeat|PeriodReader` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), 5 results

Searched for regex `.` (`boom-paper` · `logs/boom-na=4-ne=12-nf=3/scheduler.log`), 1 result

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D12-nf%3D3/wall_time.txt#1-1), lines 1 to 1

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D11-nf%3D3/wall_time.txt#1-1), lines 1 to 1

Read [](file:///home/pbachant/calkit/boom-paper/logs/boom-na%3D4-ne%3D12-nf%3D3/scheduler.log#3860-3860), lines 3860 to 3900

At t=32-33s in the ne=12 run, the filter queue is beginning to drain with final partial batches (277, 386, 733 alerts). The contrast with ne=11 is now clear. Let me look at what _run.sh actually waits for to understand what drives the end time:

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/_run.sh#1-1), lines 1 to 120

Continue to iterate?
[object Object]

User: @agent Continue: "Continue to iterate?"

GitHub Copilot: Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/_run.sh#120-120), lines 120 to 206

User: @agent Try Again

GitHub Copilot: Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/_run.sh#120-120), lines 120 to 206

I have enough evidence to explain the behavior now, and the root cause is a combination of bottleneck shifts plus a measurement artifact in the throughput harness. I’ll summarize both clearly with concrete file references.What looks like a “total workers = 19” magic point is actually not about total workers. It is a stage-balance threshold plus a timing artifact.

1. The jump is a pipeline bottleneck shift, not total-worker count
- The BOOM pipeline is staged: alert workers -> enrichment workers -> filter workers.
- In your runs, the limiting stage changes based on na/ne/nf mix, not na+ne+nf.
- With `nf=3`, the system only drops to the fast tier when upstream keeps filter workers continuously fed.
- At `na=4, ne=11, nf=3`, filter workers are often on partial batches (for example 533/591 mixed with occasional 1000), showing underfeed.
- At `na=4, ne=12, nf=3`, around the same relative time, all three filter workers are repeatedly on full 1000-item batches, so they run at capacity.

Evidence:
- Partial batches in the slower case: scheduler.log
- Full 1000 batches in the faster case: scheduler.log

2. Why the change is sharp and repeatable
- Workers sleep when input is empty (500 ms), so small underfeed creates repeated discrete stalls.
- Once ne crosses the feed threshold (11 -> 12 here), those stalls largely disappear, so wall time drops suddenly rather than gradually.
- This makes the knee look “all of a sudden” and highly repeatable.

Relevant code path:
- Enrichment/filter batch pop behavior and queue-driven loops are in base.rs and base.rs.

3. There is also a harness artifact that amplifies the plateau appearance
- The throughput script decides “filtering complete” by grepping scheduler logs for passed-filter lines and polling once per second, rather than directly counting filtered docs in Mongo.
- That introduces quantization and delay in end detection.

Evidence:
- Poll/grep completion logic in _run.sh

In short: your “jump at 19” is really “upstream feed finally keeps 3 filter workers saturated,” and the harness’s log-based completion check makes the slow tier look even more plateau-like. If you want, I can map every row in your CSV to the inferred active bottleneck stage.

User: Could we calculate some metrics in the notebook to save in the results to examine bottlenecks?

GitHub Copilot: I’ll inspect the throughput parsing script and then propose concrete notebook metrics you can compute and persist for bottleneck analysis.

Read [](file:///home/pbachant/calkit/boom-paper/results/boom.csv)

Read [](file:///home/pbachant/calkit/boom-paper/boom/tests/throughput/run.py)

Yes, this is a great next step.
You can add a bottleneck-metrics cell in analyze-logs.ipynb and write a second results table alongside boom.csv, for example results/boom_bottlenecks.csv.

The most useful metrics for your case are:

1. Filter batch fullness
- Mean filter batch size
- Fraction of filter batches that are full (size = 1000)
- Fraction of small batches (size < 500)
- This directly captures underfeeding of filter workers

2. Stage activity windows
- First/last timestamp seen for alert, enrichment, and filter workers
- Active duration per stage
- Tail idle time = end_time - last_filter_timestamp
- This reveals runs where work finishes early but measured wall time keeps running

3. Stage event rates
- Filter batch events per second
- Enrichment enqueue events per second
- Alert progress rate summary from average_rate logs
- Good for comparing where throughput saturates

4. Worker-normalized throughput
- alerts_per_second / n_alert_workers
- alerts_per_second / n_enrichment_workers
- alerts_per_second / n_filter_workers
- Helps identify overprovisioned stages

You already have the harness behavior in _run.sh, so this will complement that with richer diagnostics.

Add a new cell like this:

~~~python
import re
from pathlib import Path
import pandas as pd
import polars as pl

EXPECTED_ALERTS = 29142

# Reuse df_boom from your existing cell
# Ensure it has n_alert_workers, n_enrichment_workers, n_filter_workers, end_time, wall_time_s

def parse_ts(line: str):
    # line token 3 in your logs is the timestamp with ANSI wrappers
    tok = line.split()[2]
    tok = tok.replace("\x1b[2m", "").replace("\x1b[0m", "")
    return pd.to_datetime(tok, utc=True)

re_filter_batch = re.compile(r"\s(\d+)\/(\d+)\sZTF alerts with programid\s")
re_enrich_enq = re.compile(r"Enqueued total of (\d+) alerts to \d+ topics")
re_alert_rate = re.compile(r"average_rate=.*?([0-9]+(?:\.[0-9]+)?)")

rows = []

for r in df_boom.to_dicts():
    na = r["n_alert_workers"]
    ne = r["n_enrichment_workers"]
    nf = r["n_filter_workers"]
    cfg = f"na={na}-ne={ne}-nf={nf}"
    slog = Path(f"logs/boom-{cfg}/scheduler.log")

    if not slog.is_file():
        continue

    filter_batches = []
    enrich_enq_sizes = []
    alert_rates = []

    t_alert_first = t_alert_last = None
    t_enrich_first = t_enrich_last = None
    t_filter_first = t_filter_last = None

    with slog.open() as f:
        for line in f:
            if "alert worker" in line:
                t = parse_ts(line)
                t_alert_first = t if t_alert_first is None else t_alert_first
                t_alert_last = t
                m = re_alert_rate.search(line)
                if m:
                    alert_rates.append(float(m.group(1)))

            if "enrichment worker" in line:
                t = parse_ts(line)
                t_enrich_first = t if t_enrich_first is None else t_enrich_first
                t_enrich_last = t
                m = re_enrich_enq.search(line)
                if m:
                    enrich_enq_sizes.append(int(m.group(1)))

            if "filter worker" in line:
                t = parse_ts(line)
                t_filter_first = t if t_filter_first is None else t_filter_first
                t_filter_last = t
                m = re_filter_batch.search(line)
                if m:
                    # m.group(1)=passed count for this filter, m.group(2)=batch size
                    filter_batches.append(int(m.group(2)))

    end_time = pd.to_datetime(r["end_time"], utc=True)

    filter_batch_mean = float(pd.Series(filter_batches).mean()) if filter_batches else None
    filter_batch_p50 = float(pd.Series(filter_batches).median()) if filter_batches else None
    filter_full_frac = (sum(b == 1000 for b in filter_batches) / len(filter_batches)) if filter_batches else None
    filter_small_frac = (sum(b < 500 for b in filter_batches) / len(filter_batches)) if filter_batches else None

    enrich_enq_mean = float(pd.Series(enrich_enq_sizes).mean()) if enrich_enq_sizes else None
    enrich_enq_p50 = float(pd.Series(enrich_enq_sizes).median()) if enrich_enq_sizes else None

    tail_idle_s = (end_time - t_filter_last).total_seconds() if t_filter_last is not None else None

    alert_active_s = (t_alert_last - t_alert_first).total_seconds() if (t_alert_first is not None and t_alert_last is not None) else None
    enrich_active_s = (t_enrich_last - t_enrich_first).total_seconds() if (t_enrich_first is not None and t_enrich_last is not None) else None
    filter_active_s = (t_filter_last - t_filter_first).total_seconds() if (t_filter_first is not None and t_filter_last is not None) else None

    aps = EXPECTED_ALERTS / r["wall_time_s"]

    rows.append(
        {
            "n_alert_workers": na,
            "n_enrichment_workers": ne,
            "n_filter_workers": nf,
            "wall_time_s": r["wall_time_s"],
            "alerts_per_second": aps,
            "aps_per_alert_worker": aps / na,
            "aps_per_enrichment_worker": aps / ne,
            "aps_per_filter_worker": aps / nf,
            "filter_batch_mean": filter_batch_mean,
            "filter_batch_p50": filter_batch_p50,
            "filter_full_frac": filter_full_frac,
            "filter_small_frac_lt500": filter_small_frac,
            "enrich_enqueue_mean": enrich_enq_mean,
            "enrich_enqueue_p50": enrich_enq_p50,
            "alert_rate_mean": float(pd.Series(alert_rates).mean()) if alert_rates else None,
            "alert_active_s": alert_active_s,
            "enrich_active_s": enrich_active_s,
            "filter_active_s": filter_active_s,
            "tail_idle_s": tail_idle_s,
        }
    )

df_boom_bottlenecks = pl.DataFrame(rows).sort(
    ["n_alert_workers", "n_enrichment_workers", "n_filter_workers"]
)

df_boom_bottlenecks.write_csv("results/boom_bottlenecks.csv")
df_boom_bottlenecks
~~~

Then a quick view cell to inspect likely bottleneck signatures:

~~~python
df_boom_bottlenecks.select(
    [
        "n_alert_workers",
        "n_enrichment_workers",
        "n_filter_workers",
        "wall_time_s",
        "alerts_per_second",
        "filter_batch_mean",
        "filter_full_frac",
        "filter_small_frac_lt500",
        "tail_idle_s",
    ]
).sort("alerts_per_second", descending=True).head(20)
~~~

If you want, I can also propose a single composite bottleneck score (0 to 1) built from low filter_full_frac + high small-batch fraction + high tail_idle_s so you can rank runs by likely starvation severity.
