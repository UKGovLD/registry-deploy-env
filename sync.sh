#!/bin/bash
# Manual sync to deployed instance
rsync -avz -e "ssh" --rsync-path="sudo rsync" ldregistry/ aws-defra:/opt/ldregistry/
