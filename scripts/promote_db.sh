#!/bin/bash
# Promote Cloud SQL Read Replica to Primary during Regional Migration

# Exit on error
set -e

# Configuration
REPLICA_INSTANCE_NAME="demo-db-th"

echo "!!! CAUTION: This will promote the read replica '$REPLICA_INSTANCE_NAME' to a standalone primary instance."
echo "This is a one-way operation during a regional failover/migration."
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo "Promoting replica: $REPLICA_INSTANCE_NAME..."
gcloud sql instances promote-replica $REPLICA_INSTANCE_NAME

echo "Success! Instance '$REPLICA_INSTANCE_NAME' is now a primary instance."
echo "New IP Address:"
gcloud sql instances describe $REPLICA_INSTANCE_NAME --format="value(ipAddresses[0].ipAddress)"
echo "Next step: Update your GKE Deployment 'DB_HOST' environment variable to this new IP."
