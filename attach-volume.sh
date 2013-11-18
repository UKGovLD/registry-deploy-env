#!/bin/bash

[[ $# = 1 ]] || { echo "Usage: $0 volume-id" 1>&2 ; exit 1 ; }
VOL=$1
INSTANCE=`cat .vagrant/machines/aws/aws/id`

. lib.sh
check-installs

echo "Attaching volume to instance $INSTANCE ..."
aws ec2 attach-volume --volume-id $VOL --instance-id $INSTANCE --device /dev/xvdf
wait-for "aws ec2 describe-volumes --volume-id $VOL" ".Volumes[0].Attachments[0].State" "attached" || {	echo "Volume attachment failed" 1>&2 ; 	exit 1; }
