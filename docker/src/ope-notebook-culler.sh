#!/bin/bash

echo "Running ope-notebook-culler.sh..."

#threshold to stop running notebooks. Currently set to 24 hours
cutoff_time=86400
current_time=$(date +%s)
notebooks=$(oc get notebooks -n ope-rhods-testing-1fef2f -o jsonpath='{range .items[?(@.status.containerState.running)]}{.metadata.name}{" "}{.metadata.namespace}{" "}{.status.containerState.running.startedAt}{"\n"}{end}')
if [ -z "$notebooks" ]; then
	echo "No running notebooks found"
    exit 0
fi                    

# Loop through each notebook
while read -r nb ns ts; do
	timestamp=$(date -d $ts +%s)
    difference=$((current_time - timestamp))
    if [ $difference -gt $cutoff_time ]; then
    	echo "$nb is more than 24 hours old, stopping the notebook"
        oc patch notebook $nb -n $ns --type merge -p '{"metadata":{"annotations":{"kubeflow-resource-stopped":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}}}'
    fi
done <<< "$notebooks"

echo "ope-notebook-culler.sh run complete."
