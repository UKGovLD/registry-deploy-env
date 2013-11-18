#!/bin/bash
. lib.sh
check-installs
aws ec2 describe-snapshots --filter "Name=description,Values=Incremental backup for RegistryVol"  | jq '.Snapshots[] | {StartTime, SnapshotId}'