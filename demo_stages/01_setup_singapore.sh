#!/bin/bash
# Stage 1: Initial Setup - Singapore (Primary)
set -e

PROJECT_ID=$(gcloud config get-value project)
REGION_SG="asia-southeast1"
CLUSTER_SG="cluster-sg"

echo "=== STAGE 1: Provisioning Singapore Baseline ==="

# 0. Provision Networking
echo "--> Provisioning VPC Networking..."
./infra/setup_network.sh

# 1. Provision Database
echo "--> Provisioning Cloud SQL Primary in $REGION_SG..."

./infra/setup_db.sh

# 2. Provision GKE Cluster
echo "--> Provisioning Standard GKE Cluster in $REGION_SG..."
./infra/setup_gke.sh singapore

# 3. Instructions for User
echo "--------------------------------------------------"
echo "STAGE 1 COMPLETE"
echo "Next Steps:"
echo "1. Update k8s/deployment.yaml with Project ID and Primary DB IP."
echo "2. Deploy to Singapore: kubectl --context=gke_${PROJECT_ID}_${REGION_SG}_${CLUSTER_SG} apply -f k8s/deployment.yaml -f k8s/service.yaml -f k8s/service-lb.yaml"
echo "3. Run performance test: python scripts/performance_test.py http://<SG_REGIONAL_LB_IP>/status"
echo "--------------------------------------------------"
