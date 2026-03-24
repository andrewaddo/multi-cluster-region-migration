#!/bin/bash
# Stage 3: Regional Switch (Migration)
set -e

SOURCE=$1
DEST=$2

PROJECT_ID=$(gcloud config get-value project)
REGION_SG="asia-southeast1"
CLUSTER_SG="cluster-sg"

if [[ "$SOURCE" != "singapore" && "$SOURCE" != "thailand" ]]; then
    echo "Usage: $0 {singapore|thailand} {thailand|singapore}"
    exit 1
fi

echo "=== STAGE 3: Migrating Traffic from $SOURCE to $DEST ==="

# 1. Update Traffic Routing (Shift to DEST)
echo "--> Shifting traffic by managing ServiceExports..."
if [[ "$DEST" == "thailand" ]]; then
    echo "    - Draining Singapore (Deleting ServiceExport)..."
    kubectl --context=gke_${PROJECT_ID}_asia-southeast1_cluster-sg delete -f k8s/service-export.yaml
else
    echo "    - Draining Thailand (Deleting ServiceExport)..."
    kubectl --context=gke_${PROJECT_ID}_asia-southeast3_cluster-th delete -f k8s/service-export.yaml
fi

# 2. Database Failover
if [[ "$DEST" == "thailand" ]]; then
    echo "--> Running Database Failover (Promoting Thailand)..."
    ./scripts/promote_db.sh
else
    echo "--> Migrating back to Singapore (Requires database sync check)..."
    # Note: Moving back to SG requires a reverse replica setup which 
    # Cloud SQL supports through its 'Replication' UI/API.
    echo "!!! CAUTION: Fail-back requires manual setup of a new SG replica if TH is promoted."
fi

echo "--------------------------------------------------"
echo "MIGRATION INITIATED"
echo "Monitor performance report: python scripts/performance_test.py http://<GATEWAY_IP>/status"
echo "--------------------------------------------------"
