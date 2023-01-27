all: login init demostack apply
.PHONY: all doormat_creds doormat_aws deploy destroy console
TFC_ORG = emea-se-playground-2019
WORKSPACE_DEMOSTACK = andre-AWS-Demostack
WORKSPACE_DNS = andre-DNS-Zone
login:
	doormat login
init:
	terraform init
demostack:
	doormat aws --account se_demos_dev tf-push --local
apply:
	terraform init
	terraform plan
	terraform apply
destroy:
	terraform destroy