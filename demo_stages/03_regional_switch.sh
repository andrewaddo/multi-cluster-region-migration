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

# 1. Update HTTPRoute (Simulated Weight Shift)
# In a real demo, we should use kubectl patch or have pre-made route files.
# For simplicity, we point the user to the file.
echo "--> Update weights in k8s/httproute.yaml:"
if [[ "$DEST" == "thailand" ]]; then
    echo "    - singapore: 0"
    echo "    - thailand: 100"
else
    echo "    - singapore: 100"
    echo "    - thailand: 0"
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
