#!/bin/bash
# Setup VPC Networking for Multi-Region Demo
set -e

PROJECT_ID=$(gcloud config get-value project)
VPC_NAME="migration-vpc"
REGION_SG="asia-southeast1"
REGION_TH="asia-southeast3"

echo "=== Setting up Networking in Project: $PROJECT_ID ==="

# 1. Enable APIs
echo "--> Enabling Networking APIs..."
gcloud services enable compute.googleapis.com servicenetworking.googleapis.com

# 2. Create VPC
echo "--> Creating VPC: $VPC_NAME..."
if ! gcloud compute networks describe $VPC_NAME > /dev/null 2>&1; then
    gcloud compute networks create $VPC_NAME --subnet-mode=custom
else
    echo "    VPC $VPC_NAME already exists."
fi

# 3. Create Subnets
echo "--> Creating Subnet for Singapore ($REGION_SG)..."
if ! gcloud compute networks subnets describe migration-sg --region=$REGION_SG > /dev/null 2>&1; then
    gcloud compute networks subnets create migration-sg \
        --network=$VPC_NAME \
        --region=$REGION_SG \
        --range=10.0.1.0/24
else
    echo "    Subnet migration-sg already exists."
fi

echo "--> Creating Subnet for Thailand ($REGION_TH)..."
if ! gcloud compute networks subnets describe migration-th --region=$REGION_TH > /dev/null 2>&1; then
    gcloud compute networks subnets create migration-th \
        --network=$VPC_NAME \
        --region=$REGION_TH \
        --range=10.0.2.0/24
else
    echo "    Subnet migration-th already exists."
fi

# 4. Configure Private Services Access (for Cloud SQL)
echo "--> Allocating IP range for Private Services Access..."
if ! gcloud compute addresses describe google-managed-services-$VPC_NAME --global > /dev/null 2>&1; then
    gcloud compute addresses create google-managed-services-$VPC_NAME \
        --global \
        --purpose=VPC_PEERING \
        --prefix-length=16 \
        --network=$VPC_NAME
else
    echo "    IP range already allocated."
fi

echo "--> Creating VPC Peering for Services..."
# This command is naturally idempotent (it will just return success if already connected)
# But let's wrap it for cleaner output
if ! gcloud services vpc-peerings list --network=$VPC_NAME | grep -q "servicenetworking.googleapis.com"; then
    gcloud services vpc-peerings connect \
        --service=servicenetworking.googleapis.com \
        --ranges=google-managed-services-$VPC_NAME \
        --network=$VPC_NAME
else
    echo "    VPC Peering already established."
fi

echo "Networking setup complete!"
