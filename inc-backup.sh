#!/bin/bash
. lib.sh

# Credentials for EA backup-user - limited privileges so OK to have inline
export AWS_ACCESS_KEY_ID=AKIAJXBQWSEOS55JZOZQ
export AWS_SECRET_ACCESS_KEY=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
export AWS_DEFAULT_REGION=eu-west-1

VOL=`aws ec2 describe-volumes --filters "Name=tag:Name,Values=RegistryVol" | jq .Volumes[0].VolumeId | sed -e 's/"\(.*\)"/\1/'`
if [[ -z $VOL ]]; then
	echo "Failed to locate volume to backup" 1>&2 
	exit 1
fi
echo "Performing incremental backup for volume $VOL..."

SNAPSHOT=`aws ec2 create-snapshot --volume-id $VOL --description "Incremental backup for RegistryVol"  | jq .SnapshotId | sed -e 's/"\(.*\)"/\1/'` &&
aws ec2 create-tags --resources $SNAPSHOT --tags "Key=Name,Value=RegistryVol-backup" &&
wait-for "aws ec2 describe-snapshots --snapshot-ids $SNAPSHOT" ".Snapshots[0].State" "completed"
if [[ $? -ne 0 ]]; then
	echo "Backup failed" 1>&2 
	exit 1
fi
echo "Backup up to $SNAPSHOT"