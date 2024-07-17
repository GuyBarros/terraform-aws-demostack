all: login init demostack apply
.PHONY: all doormat_creds doormat_aws deploy destroy console
TFC_ORG = emea-se-playground-2019
WORKSPACE_DEMOSTACK = GUY-HCP-Demostack-AWS
DOORMAT_AWS_ACCOUNT = aws_guy_test
VARIABLE_SET_ID = varset-BDhuaxrwsjowYcFX
login:
		doormat login
init:
		terraform init
demostack:
		doormat aws --account $(DOORMAT_AWS_ACCOUNT)  tf-push --local
varset:
		doormat aws tf-push variable-set --account $(DOORMAT_AWS_ACCOUNT) --id $(VARIABLE_SET_ID)
apply:
		terraform init
		terraform plan
		terraform apply
destroy:
		terraform destroy