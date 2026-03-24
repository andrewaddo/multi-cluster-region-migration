# Performance Testing Guide: Multi-Region Migration

This guide details the exact procedures for conducting performance and availability testing across the three stages of the multi-cluster migration demo. The goal is to empirically prove **zero downtime** and observe latency changes as traffic shifts between regions.

## Prerequisites
Ensure the testing script is available and dependencies are installed:
```bash
# Verify Python and dependencies
python3 -c "import requests; print('requests installed')" || pip3 install requests
```

---

## 1. Before Migration (Baseline LB in Singapore)

**Objective:** Establish the baseline performance metrics (latency, throughput, error rate) when 100% of traffic is routed to the primary region (Singapore) using a standard Regional Load Balancer.

**Execution:**
Once Stage 1 is complete and the Singapore cluster is running, you will have a Regional `LoadBalancer` (e.g., 35.240.142.167) routing to Singapore.

```bash
# Command: Run a 60-second baseline test at 5 Requests Per Second
python3 scripts/performance_test.py http://<SG_REGIONAL_LB_IP>/status --rps 5 --duration 60 --output stage1_baseline.csv
```

**Expected Results:**
*   **Error Rate:** 0.00%
*   **Traffic Distribution:** `cluster-sg`: 100%
*   **Latency:** Note the `Average Latency` and `P95 Latency` (e.g., ~6ms to 8ms for local intra-region routing).

---

## 2. Introduce Expansion (Multi-Cluster Gateway)

**Objective:** After Stage 2 (Thailand cluster created), the Multi-Cluster Gateway (MCG) is introduced. Verify that the global load balancer correctly routes traffic and observe any changes in baseline latency when using the Gateway API.

**Execution:**
Start routing test traffic to the new Global Gateway IP instead of the local Regional LB.

```bash
# Command: Run a 60-second baseline test against the Gateway IP
python3 scripts/performance_test.py http://<GATEWAY_IP>/status --rps 5 --duration 60 --output stage2_mcg_baseline.csv
```

**Expected Results:**
*   **Error Rate:** 0.00%
*   **Traffic Distribution:** Likely `cluster-sg`: 100% (due to Anycast routing users to the nearest healthy cluster), but the connection goes through the Global LB.

---

## 3. During Migration (The Switch-Over)

**Objective:** Prove that during the traffic shift across the MCG and the database failover, no HTTP requests are dropped, demonstrating a zero-downtime migration.

**Execution:**
This test runs continuously (infinite duration) against the Gateway IP in the background or a separate terminal while you execute the Stage 3 migration steps.

**Terminal 1 (The Load Tester):**
```bash
# Command: Run continuously (duration 0) against the Multi-Cluster Gateway IP
python3 scripts/performance_test.py http://<GATEWAY_IP>/status --rps 5 --duration 0 --output migration_transition.csv
```

**Terminal 2 (The Operator):**
While Terminal 1 is running, execute the migration steps:
1.  Drain the Singapore cluster by deleting its `ServiceExport`: 
    `kubectl --context=gke_multi-cluster-migration_asia-southeast1_cluster-sg delete -f k8s/service-export.yaml`
2.  Promote the Database: `./scripts/promote_db.sh` (answer 'y' to the prompt)

**Expected Results (Observed in Terminal 1):**
*   **Real-time Output:** You will see the log output change dynamically from `cluster-sg` to `cluster-th`.
*   **Error Rate:** Must remain at 0.00% throughout the entire transition.
*   **Stop Test:** Once 100% of requests are hitting `cluster-th` consistently, press `Ctrl+C` in Terminal 1 to stop the test and generate the report.

---

## 4. After Migration (Settle to Regional LB in Thailand)

**Objective:** After the migration is complete and the MCG is torn down (Stage 4), establish the final baseline performance metrics on the new Regional Load Balancer in Thailand.

**Execution:**
Run a final fixed-duration test against the new Thailand Regional LB IP.

```bash
# Command: Run a 60-second baseline test
python3 scripts/performance_test.py http://<TH_REGIONAL_LB_IP>/status --rps 5 --duration 60 --output stage4_post_migration.csv
```

**Expected Results:**
*   **Error Rate:** 0.00%
*   **Traffic Distribution:** `cluster-th`: 100%
*   **Latency Comparison:** Compare this `P95 Latency` to the Stage 1 baseline. If you are testing from Singapore, the latency to Thailand should be slightly higher (reflecting the physical distance between regions), proving that traffic is truly being served from the new region natively.

---

## 5. Analyzing the Data

After completing all three phases, you will have three CSV files:
1.  `stage1_baseline.csv`
2.  `migration_transition.csv`
3.  `stage4_post_migration.csv`

**How to use this data:**
*   **Zero-Downtime Proof:** Open `migration_transition.csv` and filter by the `status_code` column. If all entries are `200`, the migration was seamless.
*   **Latency Graphing:** You can import these CSVs into Excel, Google Sheets, or a graphing tool to visualize the exact moment the traffic shifted by plotting the `latency` column against the `timestamp`. You should see a distinct step-change in latency corresponding to the regional shift.