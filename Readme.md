# Graduation project

To start, you need to adjust the project id in GCP and the name of the bucket for the backend.

Other variables can be adjusted if desired.

Terraform init, terraform plan, terraform apply -auto-approve commands.

Then everything happens automatically.

There is no sensitive data.

The keys are generated during the initialization of the environment and are laid out in the right places.

The private key (for further access to the environment) is copied to the machine from where the terraform was launched.

After the servers are deployed, ansible is installed, inventory is created, and configuration takes place.
Inventory is created on the data received from ouptut terraform,
The Ansible playbook is also copied from the repository.

Ansible uses roles. The installation of your favorite software, the installation of docker, the installation of Jenkins, the creation of users for Jenkins (because dev and kuber are used as nodes for Jenkins), the deployment of k8s and tools for working with it.


The time of full automatic deployment of the necessary environment is 6 minutes.
The repository of this step with all files is the current one.
