# BU-RHOAI

This repository is a collection of useful scripts and tools for TAs and professors to manage students workloads.

## get_url.py
=======
## Cronjobs

### ope-notebook-culler

This cronjob runs once every 24 hours at 7am, removing all notebooks & pvcs from the rhods-notebooks namespace. To add resources to the rhods-notebooks namespace:

1. Ensure you are logged in to your OpenShift account via the CLI and you have access to rhods-notebooks namespace.
2. Switch to rhods-notebooks namespace:
```
	oc project rhods-notebooks
```

3. From cronjobs/ope-notebook-culler/ directory run:
```
	oc apply -k .
```

	This will deploy all the necessary resources for the cronjob to run on the specified schedule.

Alternatively, to run the script immediately: 

1. Ensure you followed the steps above
2. Verify the cronjob ope-notebook-culler exists
```
	oc get cronjob ope-notebook-culler
```

3. Run:
```
	kubectl create -n rhods-notebooks job --from=cronjob/ope-notebook-culler ope-notebook-culler
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