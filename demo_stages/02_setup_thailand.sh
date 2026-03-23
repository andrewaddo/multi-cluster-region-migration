#!/bin/bash
# Stage 2: Expansion - Thailand (Secondary)
set -e

PROJECT_ID=$(gcloud config get-value project)
REGION_SG="asia-southeast1"
REGION_TH="asia-southeast3"
CLUSTER_SG="cluster-sg"
CLUSTER_TH="cluster-th"

echo "=== STAGE 2: Provisioning Thailand Expansion ==="

# 1. Provision Cluster in Thailand and Configure Fleet/Gateway
./infra/setup_gke.sh thailand

# 2. Deployment Instructions
echo "--------------------------------------------------"
echo "STAGE 2 COMPLETE"
echo "Next Steps:"
echo "1. Deploy to Thailand: kubectl --context=gke_${PROJECT_ID}_${REGION_TH}_${CLUSTER_TH} apply -f k8s/deployment.yaml"
echo "2. Deploy Gateway: kubectl --context=gke_${PROJECT_ID}_${REGION_SG}_${CLUSTER_SG} apply -f k8s/gateway.yaml"
echo "3. Deploy HTTPRoute: kubectl --context=gke_${PROJECT_ID}_${REGION_SG}_${CLUSTER_SG} apply -f k8s/httproute.yaml"
echo "--------------------------------------------------"
