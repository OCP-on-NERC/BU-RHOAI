# BU-RHOAI

This repository is a collection of useful scripts and tools for TAs and professors to manage students workloads.

## Cronjobs

### group-sync

This cronjob runs once every hours at the top of the hour, adding all users with the edit rolebinding in the specified namespace to the specified group.
This offers us a way to keep class users added to course namespaces via ColdFront in sync with the in cluster OCP course group. To run this cronjob:

1. Ensure you are logged in to your OpenShift account via the CLI and you have access to rhods-notebooks namespace.
2. Switch to your course namespace:
```
    oc project <namespace>
```

3. Update the `GROUP_NAME` and `NAMESPACE` env variables in cronjobs/group-sync/cronjob.yaml and update `namespace` variable in kustomization.yaml
4. From cronjobs/group-sync/ directory run:
```
    oc apply -k . --as system:admin
```

This will deploy all the necessary resources for the cronjob to run on the specified schedule.(Every hour by default)

Alternatively, to run the script immediately:

1. Ensure you followed the steps above
2. Verify the cronjob `group-sync` exists
```
    oc get cronjob group-sync
```

3. Run:
```
    kubectl create -n <class_namespace> job --from=cronjob/group-sync group-sync
```

### nb-culler

This cronjob runs once every hours at the top of the hour, exclusively applied to notebooks associated with specific user group  and will not impact other notebooks within the rhods-notebooks namespace. The cronjob performs the following action:

1. **Shuts down notebooks exceeding X hours of runtime**: any notebook found to have been running for more than X hours will be gracefully shut down to conserve resources. PVCs persist the shutdown process.

To add resources to the rhods-notebooks namespace:

1. Ensure you are logged in to your OpenShift account via the CLI and you have access to rhods-notebooks namespace.
2. Switch to rhods-notebooks namespace:
```
    oc project rhods-notebooks
```

3. Ensure the environment variables for `GROUP_NAME`, and `CUTOFF_TIME` (seconds) are correctly set.

4. From cronjobs/nb-culler/ directory run:
```
    oc apply -k . --as system:admin
```

This will deploy all the necessary resources for the cronjob to run on the specified schedule.

Alternatively, to run the script immediately:

1. Ensure you followed the steps above
2. Verify the cronjob `nb-culler` exists
```
    oc get cronjob nb-culler
```

3. Run:
```
    kubectl create -n rhods-notebooks job --from=cronjob/nb-culler nb-culler
```

This will trigger the cronjob to spawn a job manually.


## Scripts

### get_url.py

This script is used to retrieve the URL for a particular notebook associated with one student. To execute this script:

1. Ensure you are logged in to your OpenShift account via the CLI and you have access to rhods-notebooks namespace.
2. TAs can list all notebooks under rhods-notebooks namespace via the CLI
    ```
    oc get notebooks -n rhods-notebooks
    ```
3. Before running this script, ensure that pyyaml is installed in your Python environment:
    ```
    pip install pyyaml
    ```
4. Run the script:
    ```
    python get_url.py
    ```
    It prompts the user to enter the notebook name. Output will look something like:
    ```
    Enter the notebook name: xxx
    URL for notebook xxx: xxx
    ```

## Webhooks

### assign-class-label

This script is used to add labels to the pod of a user denoting which class they belong to (class="classname"). This allows us to differentiate between users of different classes running in the same namespace. This also allows us to create validating [gatekeeper policies](https://github.com/OCP-on-NERC/gatekeeper) for each class.

Before using the assign-class-label webhook, the group-sync cronjob should be run so that the users of the different classes are added to their respective groups in openshift.

In order to modify the deployment follow these steps:

1. Modify the GROUPS env variable to contain the list of classes (openshift groups) of which you would like to assign class labels. This file is found here: webhooks/assign-class-label/deployment.yaml

2. Generate a new OpenSSL certificate

    ```
    openssl req -x509 -sha256 -newkey rsa:2048 -keyout webhook.key -out webhook.crt -days 1024 -nodes -addext "subjectAltName = DNS.1:service_name.namespace.svc"
    ```

    When deployed to rhods-notebooks the command was specified as such:

    ```
    openssl req -x509 -sha256 -newkey rsa:2048 -keyout webhook.key -out webhook.crt -days 1024 -nodes -addext "subjectAltName = DNS.1:assign-class-label-webhook.rhods-notebooks.svc"
    ```

3. Add the cert and key to the required resources:

    ```
    cat webhook.crt | base64 | tr -d '\n'
    ```

    ```
    cat webhook.key | base64 | tr -d '\n'
    ```

    This will encode the certificate and key in base64 format which is required. Copy the output of the webhook.crt to the caBundle in webhooks/assign-class-label/webhook-config.yaml. Then create a secret.yaml that looks like this

    ```
    apiVersion: v1
    kind: Secret
    metadata:
        name: webhook-cert
    type: Opaque
    data:
        webhook.crt:
        webhook.key:
    ```

    Copy and paste the output of the cat command to the respective fields for webhook.crt and webhook.key. Then execute

    ```
    oc apply -f secret.yaml --as system:admin
    ```

    within the same namespace that your webhook will be deployed to.


4. Change namespace variable in the kubernetes manifests to match namespace you want the webhook to be deployed to.

5. From webhooks/assign-class-label/ directory run:
```
    oc apply -k . --as system:admin
```

***Steps 2, 3, and 4 are only required if you are deploying to a new namespace/environment.***

The python script and docker image used for the webserver should not need changes made to it. But in the case that changes must be made, the Dockerfile and python script can be found at docker/src/python/assign-class-label/.
