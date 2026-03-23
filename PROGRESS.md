# Project Progress

## Ultimate Goal
- [ ] Complete the Multi-Cluster / Multi-Region Migration Demo on GCP.
- [ ] Demonstrate zero-downtime regional migration from Singapore (asia-southeast1) to Thailand (asia-southeast3).

## Milestones
- [ ] Stage 1: Initial Baseline (Singapore)
- [ ] Stage 2: Regional Expansion (Thailand)
- [ ] Stage 3: Controlled Migration (Switch-Over)

## Completed Tasks
- [x] Scaffold project directories (`app/`, `demo_stages/`, `infra/`, `k8s/`, `scripts/`).
- [x] Provision VPC networking.
- [x] Provision Cloud SQL Primary (Singapore) and Replica (Thailand).
- [x] Provision Singapore GKE Cluster (`cluster-sg`).
- [x] Register Singapore Cluster to GCP Fleet.

## Current Task
- [ ] **WIP**: Deploy and verify application in Singapore (Stage 1 Baseline).
    - [x] Infrastructure provisioned successfully.
    - [ ] Update `k8s/deployment.yaml` with Project ID and DB IP (`10.250.0.3`).
    - [ ] Build and push Docker image `gcr.io/multi-cluster-migration/demo-app:v1`.
    - [ ] Deploy to GKE and verify `/status` endpoint.
    - [ ] Run baseline performance test.

## Pending Tasks
- [ ] Implement `demo_stages/01_setup_singapore.sh`
- [ ] Implement `demo_stages/02_setup_thailand.sh`
- [ ] Implement `demo_stages/03_regional_switch.sh`
- [ ] Implement infrastructure scripts in `infra/`
- [ ] Implement Kubernetes manifests in `k8s/`
- [ ] Implement application in `app/`
- [ ] Implement testing tools in `scripts/`

---
*Note: This file tracks our current state to easily resume after any disruptions. We will stage and commit to Git upon reaching a milestone.*
