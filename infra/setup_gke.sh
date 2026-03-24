#!/bin/bash
# Provision GKE Clusters and Register to Fleet for Multi-Cluster Gateway

# Exit on error
set -e

# Configuration
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_SG="cluster-sg"
REGION_SG="asia-southeast1"
CLUSTER_TH="cluster-th"
REGION_TH="asia-southeast3"

# 1. Enable Required APIs (just in case)
echo "Enabling APIs..."
gcloud services enable \
    container.googleapis.com \
    gkehub.googleapis.com \
    multiclusterservicediscovery.googleapis.com \
    multiclusteringress.googleapis.com \
    trafficdirector.googleapis.com

# Function to create Singapore Cluster (Standard)
setup_singapore() {
    echo "Creating Standard GKE Cluster: $CLUSTER_SG in $REGION_SG..."
    if ! gcloud container clusters describe $CLUSTER_SG --region=$REGION_SG > /dev/null 2>&1; then
        gcloud container clusters create $CLUSTER_SG \
            --region=$REGION_SG \
            --num-nodes=1 \
            --machine-type=n4-standard-4 \
            --disk-size=50GB \
            --network=migration-vpc \
            --subnetwork=migration-sg \
            --enable-ip-alias \
            --enable-private-nodes \
            --master-ipv4-cidr=172.16.0.16/28 \
            --enable-shielded-nodes \
            --shielded-secure-boot \
            --shielded-integrity-monitoring \
            --workload-pool=$PROJECT_ID.svc.id.goog \
            --project=$PROJECT_ID
    else
        echo "    Cluster $CLUSTER_SG already exists."
    fi

    echo "Registering $CLUSTER_SG to the Fleet..."
    if ! gcloud container fleet memberships describe $CLUSTER_SG > /dev/null 2>&1; then
        gcloud container fleet memberships register $CLUSTER_SG \
            --gke-cluster=$REGION_SG/$CLUSTER_SG \
            --enable-workload-identity \
            --location=global
    else
        echo "    Membership $CLUSTER_SG already exists."
    fi
}

# Function to create Thailand Cluster (Standard)
setup_thailand() {
    echo "Creating Standard GKE Cluster: $CLUSTER_TH in $REGION_TH..."
    if ! gcloud container clusters describe $CLUSTER_TH --region=$REGION_TH > /dev/null 2>&1; then
        # Using c4-standard-4 as e2-standard-4 is not available in asia-southeast3
        gcloud container clusters create $CLUSTER_TH \
            --region=$REGION_TH \
            --num-nodes=1 \
            --machine-type=n4-standard-4 \
            --disk-size=50GB \
            --network=migration-vpc \
            --subnetwork=migration-th \
            --enable-ip-alias \
            --enable-private-nodes \
            --master-ipv4-cidr=172.16.0.32/28 \
            --enable-shielded-nodes \
            --shielded-secure-boot \
            --shielded-integrity-monitoring \
            --workload-pool=$PROJECT_ID.svc.id.goog \
            --project=$PROJECT_ID
    else
        echo "    Cluster $CLUSTER_TH already exists."
    fi

    echo "Registering $CLUSTER_TH to the Fleet..."
    if ! gcloud container fleet memberships describe $CLUSTER_TH > /dev/null 2>&1; then
        gcloud container fleet memberships register $CLUSTER_TH \
            --gke-cluster=$REGION_TH/$CLUSTER_TH \
            --enable-workload-identity \
            --location=global
    else
        echo "    Membership $CLUSTER_TH already exists."
    fi

    echo "Enabling Multi-Cluster Services and Gateway API..."
    gcloud container fleet multi-cluster-services enable
    gcloud container fleet ingress enable --config-membership=$CLUSTER_SG
}

case "$1" in
    singapore)
        setup_singapore
        ;;
    thailand)
        setup_thailand
        ;;
    *)
        echo "Usage: $0 {singapore|thailand}"
        exit 1
        ;;
esac

echo "Infrastructure ready!"
echo "Next: Build your app and apply Kubernetes manifests."
