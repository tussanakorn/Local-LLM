#!/bin/bash

# Variables
DB_CONTAINER="passbolt-db-1"  # Name of the database container
PASSBOLT_CONTAINER="passbolt-passbolt-1"  # Name of the Passbolt container
AWS_BUCKET="s3://passbolt-data-backup"  # AWS S3 bucket base path
DATE=$(date +'%Y-%m-%d')  # Date format for naming backups

# Step 1: Backup MySQL Database and upload to s3://passbolt-data-backup/database/
echo "Step 1: Dumping MySQL database from container $DB_CONTAINER and uploading to S3 (database path)..."
sudo docker exec -i $DB_CONTAINER bash -c \
'mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}' \
| aws s3 cp - $AWS_BUCKET/database/backup_$DATE.sql

if [ $? -eq 0 ]; then
    echo "Database dump and upload to S3 (database path) successful."
else
    echo "Error: Database dump or upload to S3 (database path) failed." >&2
    exit 1
fi

# Step 2: Backup GPG keys and upload to s3://passbolt-data-backup/gpg_keys/
echo "Step 2: Copying and uploading GPG private key from $PASSBOLT_CONTAINER to S3 (gpg_keys path)..."
sudo docker cp $PASSBOLT_CONTAINER:/etc/passbolt/gpg/serverkey_private.asc - \
| aws s3 cp - $AWS_BUCKET/gpg_keys/serverkey_private_$DATE.asc

if [ $? -eq 0 ]; then
    echo "GPG private key uploaded successfully to S3 (gpg_keys path)."
else
    echo "Error: Failed to upload GPG private key to S3 (gpg_keys path)." >&2
    exit 1
fi

echo "Copying and uploading GPG public key from $PASSBOLT_CONTAINER to S3 (gpg_keys path)..."
sudo docker cp $PASSBOLT_CONTAINER:/etc/passbolt/gpg/serverkey.asc - \
| aws s3 cp - $AWS_BUCKET/gpg_keys/serverkey_$DATE.asc

if [ $? -eq 0 ]; then
    echo "GPG public key uploaded successfully to S3 (gpg_keys path)."
else
    echo "Error: Failed to upload GPG public key to S3 (gpg_keys path)." >&2
    exit 1
fi

# Step 3: Backup Passbolt configuration file and upload to s3://passbolt-data-backup/config/
echo "Step 3: Copying and uploading Passbolt config file from $PASSBOLT_CONTAINER to S3 (config path)..."
sudo docker cp $PASSBOLT_CONTAINER:/etc/passbolt/passbolt.default.php - \
| aws s3 cp - $AWS_BUCKET/config/passbolt_$DATE.php

if [ $? -eq 0 ]; then
    echo "Passbolt config file uploaded successfully to S3 (config path)."
else
    echo "Error: Failed to upload Passbolt config file to S3 (config path)." >&2
    exit 1
fi

# Final Step: Completion message
echo "Backup process completed successfully and uploaded to S3."
