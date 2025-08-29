#!/bin/bash

CLASS_NAME="bu-cs599-pmpp-cuda"

create_resource_command=(oc create -f -)
openshift_url=https://rhods-dashboard-redhat-ods-applications.apps.edu.nerc.mghpcc.org/projects
# split openshift url to provide as parameters
host="${openshift_url%/projects*}"        # get everything before projects
hub_host=$host
run_name="gpu_class_test"
image_name="csw-dev-f25"

create_wb() {
    random_id=$(openssl rand -hex 3)

    #set namespace
    namespace=$1

    username=$(oc -n "$ns" get rolebinding edit -o json \
    | jq -r '
        (.subjects // [])
        | map(.name)
        | map(select(. != "jappavoo-40bu-2edu"))
        | map(select(. != "sdanni-40redhat-2com"))
        | map(select(. != "istaplet"))
        | .[]
    ')

    user=$(oc -n "$ns" get rolebinding edit -o json \
    | jq -r '
        (.subjects // [])
        | map(.name
            | if test("@.*\\..*$")
                then sub("@"; "-40") | gsub("\\.";"-2")
                else .
                end)
        | map(select(. != "jappavoo-40bu-2edu"))
        | map(select(. != "sdanni-40redhat-2com"))
        | map(select(. != "istaplet"))
        | .[]
    ')

    # give notebook within namespace a name
    notebook_name=cs599-${user}-wb

    params=(
        -p NOTEBOOK_NAME="$notebook_name"
        -p RUN_NAME="$run_name"
        -p USERNAME="$username"
        -p NAMESPACE="$namespace"
        -p USER="$user"
        -p IMAGE_NAME="$image_name"
        -p OPENSHIFT_URL="$openshift_url"
        -p HUB_HOST="$hub_host"
    )

    oc process -f notebook_resource.yaml --local "${params[@]}" | "${create_resource_command[@]}"  --as system:admin 1>&2

    echo "$notebook_name"
}

apply_localqueue() {
    namespace=$1

    local_params=(
        -p NAMESPACE="$namespace"
    )

    oc process -f localqueue.yaml --local "${local_params[@]}" | "${create_resource_command[@]}" --as system:admin  1>&2
}

apply_rolebinding() {
    #set namespace and nb name
    namespace=$1
    notebook_name=$2

    rb_params=(
        -p NAMESPACE="$namespace"
        -p SERVICE_ACCOUNT_NB="$notebook_name"
    )

    oc process -f rb.yaml --local "${rb_params[@]}" | "${create_resource_command[@]}" --as system:admin
}

apply_clusterq() {

    oc apply -f  cluster_queue_role.yaml --as system:admin
}

apply_clusterq

oc get ns | grep "^${CLASS_NAME}-" | awk '{print $1}' | while read ns; do
    oc project "$ns"

    #create a workbench and save the name of the notebook to apply rolebindings
    nb_name="$(create_wb "$ns")"
    apply_rolebinding "$ns" "$nb_name"
    apply_localqueue "$ns"

done
