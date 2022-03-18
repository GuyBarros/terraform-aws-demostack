all: demostack dns
.PHONY: all doormat_creds doormat_aws deploy destroy console
TFC_ORG = emea-se-playground-2019
WORKSPACE_DEMOSTACK = Guy-AWS-Demostack
WORKSPACE_DNS = Guy-DNS-Zone
login:
	doormat login
demostack:
	doormat aws --account se_demos_dev tf-push --local
