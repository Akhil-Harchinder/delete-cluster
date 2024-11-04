#!/bin/bash

# Download rctl binary and configure for use
curl -s -o rctl-linux-amd64.tar.bz2 https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
chmod 0755 rctl

# Trigger path in pipeline
path="cluster-spec-file/aws/projects"

echo "Stage is: $STAGE"

# Echo pipeline defined environmental variables to verify they are properly passed in
echo "$IS_REMOVED"
echo "Removed Cluster Specs Passed In:  $REM_CLUSTER_SPEC"

# Check that path exists in removed commits then add to list
echo "Removed Cluster Specs"
initialRemArray=`echo $REM_CLUSTER_SPEC | awk -F ',' '{ s = $1; for (i = 2; i <= NF; i++) s = s "\n"$i; print s; }'`
for file3 in ${initialRemArray}
do
  echo "Filename: $file3"
  if [[ "$file3" == *"$path"* ]]; then
    echo "Add Array Element: "
    echo $file3
    updatedRemArray+=($file3)
  fi
done
echo "New List: " ${updatedRemArray[@]}

# Run for removed files
if [ $IS_REMOVED = "true" ] && [ $STAGE = "delete-cluster" ]
then
  echo "In Removed - New Removed List: " ${updatedRemArray[@]}
  for file6 in ${updatedRemArray[@]}; do
    echo "Cluster deletion in progress!"
    remSpec=$(basename $file6)
    # For each removed commit grab the cluster name from the spec file.
    CLUSTER_NAME=`echo $remSpec |cut -d '.' -f1`
    echo $CLUSTER_NAME
    # Strip off comments as these are passed to rctl
    clusterName=$(echo "$CLUSTER_NAME" | sed 's/ *[#;].*$//g' | sed 's/^ *//')
    CLUSTER_NAME=$clusterName
  
    # Use rctl to grab all projects and store into an array
    echo "Before getting projects"
    ./rctl get projects -o json -l 500
    ./rctl get projects -o json -l 500 | jq -r '.results[].name'
    proj=( $(./rctl get projects -o json -l 500 | jq -r '.results[].name') )
    echo "Projects: $proj"
    proj_len=${#proj[@]}
    echo "Project length is $proj_len"

    # For each project traverse the clusters to find it's match.
    for ((i = 0 ; i < $proj_len ; i++)); do
      echo "Project: ${proj[$i]}"
      clusters=( $(./rctl get clusters -p ${proj[$i]} -o json | jq -r '.[].name') )
      cluster_len=${#clusters[@]}

      for ((j = 0 ; j < $proj_len ; j++)); do
        tmp_cluster=${clusters[$j]}
        echo "$tmp_cluster"
        # If cluster is matched then delete the cluster with rctl.
        if [ "$tmp_cluster" = "$CLUSTER_NAME" ]
        then
          echo "./rctl delete cluster $tmp_cluster -p  ${proj[$i]} -y"
          ./rctl delete cluster $tmp_cluster -p  ${proj[$i]} -y --wait
        else
          echo "Cluster not found!"
        fi
      done
    done
  done
fi