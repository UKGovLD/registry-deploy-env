#!/bin/bash

[[ $# = 1 ]] || { echo "Usage: $0 snapshot-id" 1>&2 ; exit 1 ; }
SID=$1
INSTANCE=`cat .vagrant/machines/aws/aws/id`

. lib.sh
check-installs

aws ec2 describe-snapshots --snapshot-ids $SID || { echo "Can't find snapshot $SID" 1>&2; exit 1; }
[[ -n $INSTANCE ]] || { echo "Can't find instance to attach to" 1>&2; exit 1; }

VOL=`aws ec2 create-volume --snapshot-id $SID --availability-zone eu-west-1b | jq .VolumeId | sed -e 's/"\(.*\)"/\1/'`
echo "Creating volume $VOL ..."
wait-for "aws ec2 describe-volumes --volume-id $VOL" ".Volumes[0].State" "available" || { echo "Volume create failed" 1>&2 ; exit 1; }

echo "Attaching volume to instance $INSTANCE ..."
aws ec2 attach-volume --volume-id $VOL --instance-id $INSTANCE --device /dev/xvdf
wait-for "aws ec2 describe-volumes --volume-id $VOL" ".Volumes[0].Attachments[0].State" "attached" || {	echo "Volume attachment failed" 1>&2 ; 	exit 1; }
