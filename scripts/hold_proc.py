# Simulates a service appending to a log file continuously
import time
with open("/tmp/critical.log", "w") as f:
    for i in range(1000):
        f.write(f"Record {i}: System state nominal\n")
        f.flush()
        time.sleep(1)