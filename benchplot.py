import sys
import os
import pandas as pd
import matplotlib.pyplot as plt

args = sys.argv

csv_file = args[1]
environment = args[2]
export = args[3]

os.makedirs(export, exist_ok=True)

# read and average benchmark data
benchmark = pd.read_csv(csv_file).groupby("timegaps", as_index=False).mean()

# find thread columns
thread_cols = [c for c in benchmark.columns if c.startswith("thread")]
thread_counts = [int(c.replace("thread","")) for c in thread_cols]


# -----------------------
# Runtime plot
# -----------------------

plt.figure(figsize=(9,6))

plt.title("Runtime vs Timegaps", fontsize=16, fontweight='bold')
plt.xlabel("Timegaps", fontsize=14, fontweight='bold')
plt.ylabel("Runtime (seconds)", fontsize=14, fontweight='bold')

# serial
plt.plot(
    benchmark["timegaps"],
    benchmark["serial"],
    marker='o',
    linewidth=2,
    label="Serial"
)

# thread lines
for col, t in zip(thread_cols, thread_counts):
    plt.plot(
        benchmark["timegaps"],
        benchmark[col],
        marker='o',
        linewidth=2,
        label=f"{t} Threads"
    )

plt.grid(True, linestyle='--', linewidth=1, alpha=0.8)
plt.xticks(benchmark["timegaps"], fontsize=12)
plt.yticks(fontsize=12)
plt.legend(fontsize=12)

plt.tight_layout()
plt.savefig(os.path.join(export, "runtime.png"), dpi=300)
plt.close()


# -----------------------
# Speedup calculation
# -----------------------

speedup = benchmark[thread_cols].rdiv(benchmark["serial"], axis=0)
speedup.insert(0, "timegaps", benchmark["timegaps"])


# -----------------------
# Speedup plot
# -----------------------

plt.figure(figsize=(9,6))

plt.title("Speedup vs Threads", fontsize=16, fontweight='bold')
plt.xlabel("Threads", fontsize=14, fontweight='bold')
plt.ylabel("Speedup", fontsize=14, fontweight='bold')

# one line per timegap
for i in range(len(speedup)):
    tg = int(speedup.iloc[i]["timegaps"])   # ensure integer in legend
    plt.plot(
        thread_counts,
        speedup.iloc[i][thread_cols],
        marker='o',
        linewidth=2,
        label=f"timegap={tg}"
    )

# ideal scaling line (black)
plt.plot(
    thread_counts,
    thread_counts,
    linestyle='--',
    linewidth=2,
    color='black',
    label="Ideal"
)

plt.grid(True, linestyle='--', linewidth=1, alpha=0.8)
plt.xticks(thread_counts, fontsize=12)
plt.yticks(fontsize=12)
plt.legend(fontsize=11)

plt.tight_layout()
plt.savefig(os.path.join(export, "speedup.png"), dpi=300)
plt.close()