# Multi-Cluster / Multi-Region Migration Demo on GCP

This project demonstrates a multi-region active-active deployment and a zero-downtime migration strategy using **Google Kubernetes Engine (GKE)**, **Multi-Cluster Gateway (MCG)**, and **Cloud SQL with Cross-Region Replicas**.

## Architecture Overview

1.  **GCP Multi-Cluster Gateway**: A global L7 load balancer that routes user traffic across clusters in different regions based on proximity, health, and custom weights.
2.  **GKE Clusters**: Two clusters (`cluster-sg` in `asia-southeast1`, `cluster-th` in `asia-southeast3`) registered to a single GCP Fleet.
3.  **Application**: A simple Python FastAPI service that connects to PostgreSQL and exposes a `/status` endpoint for verifying the routing behavior.
4.  **Database**: Cloud SQL (PostgreSQL) running a Primary in `asia-southeast1` (Singapore) and a Read Replica in `asia-southeast3` (Thailand).

## Project Structure

*   `app/`: Python FastAPI backend application and Dockerfile.
*   `k8s/`: Kubernetes manifests (Deployment, Service, ServiceExport, Gateway, HTTPRoute).
*   `scripts/`: Testing tools (`test_failover.py`) to demonstrate zero downtime.
*   `infra/`: Infrastructure directory (add your Terraform/scripts here).

# GKE Multi-Region Migration Demo

This repository contains a structured, three-stage demonstration of a zero-downtime regional migration from **Singapore (asia-southeast1)** to **Thailand (asia-southeast3)**.

## Demo Stages

To make the demo repeatable and easy to follow, we have organized the execution into three main scripts in the `demo_stages/` directory.

### Stage 1: Initial Baseline (Singapore)
Set up the primary environment in Singapore with a standard Regional Load Balancer.
```bash
./demo_stages/01_setup_singapore.sh
```
*   **Actions**: Provisions Singapore DB, GKE Cluster, and a standard `LoadBalancer` service.
*   **Verification**: Deploy the app and run the performance test to see the baseline on a single cluster.

### Stage 2: Regional Expansion (Thailand & Global Gateway)
Add the Thailand region and introduce the Multi-Cluster Gateway (MCG).
```bash
./demo_stages/02_setup_thailand.sh
```
*   **Actions**: Provisions Thailand GKE Cluster, exports services from both clusters (`ServiceExport`), and configures the Global Multi-Cluster Gateway.
*   **Verification**: Traffic is now globally load-balanced via the MCG IP but still favors Singapore for local users.

### Stage 3: Controlled Migration (Switch-Over)
Perform the actual migration between regions using the Gateway.
```bash
# Migrate from Singapore to Thailand
./demo_stages/03_regional_switch.sh singapore thailand
```
*   **Actions**: Initiates traffic shift (by deleting the Singapore `ServiceExport`) and Database Promotion.
*   **Verification**: Monitor `migration_report.csv` for zero dropped requests during the shift.

### Stage 4: Post-Migration (Settle in Thailand)
Once the migration is complete, settle back to a standard Regional Load Balancer in Thailand and tear down the complex multi-cluster routing.
```bash
./demo_stages/04_post_migration.sh
```
*   **Actions**: Deploys a new `LoadBalancer` service in Thailand. Provides instructions to clean up the MCG resources and optionally decommission the old Singapore cluster.
*   **Verification**: Verify the application is fully functional on the new Thailand Regional LB IP.

### Repeatability & Fail-back
To migrate back to Singapore (Stage 4):
1.  **Re-establish Replication**: Set up a new read-replica in Singapore from the Thailand primary.
2.  **Run Switch-back**:
    ```bash
    ./demo_stages/03_regional_switch.sh thailand singapore
    ```
3.  **Finalize**: Promote the Singapore replica and update the app configuration.
