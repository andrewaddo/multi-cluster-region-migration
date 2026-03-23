#!/bin/bash
# Provision Cloud SQL Primary and Read Replica for Demo

# Exit on error
set -e

# Configuration - Update these!
PROJECT_ID=$(gcloud config get-value project)
INSTANCE_NAME_PRIMARY="demo-db-sg"
INSTANCE_NAME_REPLICA="demo-db-th"
REGION_PRIMARY="asia-southeast1"
REGION_REPLICA="asia-southeast3"
DB_PASSWORD="YourSecurePassword123" # Change this!

echo "Starting Cloud SQL Provisioning in Project: $PROJECT_ID"

# 1. Create Primary Instance in Singapore
echo "Creating Primary Instance: $INSTANCE_NAME_PRIMARY in $REGION_PRIMARY..."
if ! gcloud sql instances describe $INSTANCE_NAME_PRIMARY > /dev/null 2>&1; then
    gcloud sql instances create $INSTANCE_NAME_PRIMARY \
        --database-version=POSTGRES_15 \
        --tier=db-custom-2-7680 \
        --region=$REGION_PRIMARY \
        --root-password=$DB_PASSWORD \
        --availability-type=zonal \
        --storage-type=SSD \
        --storage-size=10GB \
        --no-assign-ip \
        --network=migration-vpc
else
    echo "    Primary $INSTANCE_NAME_PRIMARY already exists."
fi

# 2. Create Read Replica in Thailand
echo "Creating Read Replica: $INSTANCE_NAME_REPLICA in $REGION_REPLICA..."
if ! gcloud sql instances describe $INSTANCE_NAME_REPLICA > /dev/null 2>&1; then
    gcloud sql instances create $INSTANCE_NAME_REPLICA \
        --master-instance-name=$INSTANCE_NAME_PRIMARY \
        --region=$REGION_REPLICA \
        --no-assign-ip \
        --network=migration-vpc \
        --tier=db-f1-micro
else
    echo "    Replica $INSTANCE_NAME_REPLICA already exists."
fi

echo "Provisioning complete!"
echo "--------------------------------------------------"
echo "Primary Instance IP:"
gcloud sql instances describe $INSTANCE_NAME_PRIMARY --format="value(ipAddresses[0].ipAddress)"
echo "Replica Instance IP:"
gcloud sql instances describe $INSTANCE_NAME_REPLICA --format="value(ipAddresses[0].ipAddress)"
echo "--------------------------------------------------"
