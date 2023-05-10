all: login init demostack apply
.PHONY: all doormat_creds doormat_aws deploy destroy console
DOORMAT_AWS_ACCOUNT = aws_guy_test
login:
		doormat login
init:
		terraform init
demostack:
		doormat aws --account $(DOORMAT_AWS_ACCOUNT)  tf-push --local
apply:
		terraform init
		terraform plan
		terraform apply
destroy:
		terraform destroy