#!/bin/bash
# Stage 4: Post-Migration Cleanup & Settle in Thailand
set -e

PROJECT_ID=$(gcloud config get-value project)
REGION_SG="asia-southeast1"
REGION_TH="asia-southeast3"
CLUSTER_SG="cluster-sg"
CLUSTER_TH="cluster-th"

echo "=== STAGE 4: Post-Migration (Settle in Thailand) ==="

echo "--------------------------------------------------"
echo "Next Steps to settle the application in a single cluster (Thailand):"
echo "1. Deploy Regional Load Balancer to Thailand:"
echo "   kubectl --context=gke_${PROJECT_ID}_${REGION_TH}_${CLUSTER_TH} apply -f k8s/service-lb.yaml"
echo "2. Obtain the new Thailand Regional LB IP:"
echo "   kubectl --context=gke_${PROJECT_ID}_${REGION_TH}_${CLUSTER_TH} get svc demo-lb"
echo "3. (Simulated DNS Switch) Update your application/DNS to point to this new Regional IP."
echo "4. Clean up Multi-Cluster Gateway components:"
echo "   kubectl --context=gke_${PROJECT_ID}_${REGION_SG}_${CLUSTER_SG} delete -f k8s/httproute.yaml"
echo "   kubectl --context=gke_${PROJECT_ID}_${REGION_SG}_${CLUSTER_SG} delete -f k8s/gateway.yaml"
echo "   kubectl --context=gke_${PROJECT_ID}_${REGION_TH}_${CLUSTER_TH} delete -f k8s/service-export.yaml"
echo "   kubectl --context=gke_${PROJECT_ID}_${REGION_SG}_${CLUSTER_SG} delete -f k8s/service-export.yaml"
echo "5. (Optional) Decommission the Singapore Cluster if no longer needed:"
echo "   gcloud container clusters delete ${CLUSTER_SG} --region ${REGION_SG}"
echo "--------------------------------------------------"
