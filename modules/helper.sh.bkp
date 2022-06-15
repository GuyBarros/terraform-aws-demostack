#! /bin/bash
#terraform output -json > output.json

function setup-vault {
    export VAULT_SKIP_VERIFY=1
    export VAULT_NAMESPACE=admin
    export VAULT_ADDR=$(jq -r .HCP_Vault_Public_address.value output.json)
    export VAULT_TOKEN=$(jq -r .HCP_Vault_token.value output.json)
}

function setup-consul {
    export CONSUL_HTTP_TOKEN=$(jq -r .HCP_Consul_token.value output.json)
    export CONSUL_HTTP_ADDR=$(jq -r .HCP_Consul_Public_address.value output.json)
}

function setup-nomad {
    # export NOMAD_TOKEN=$(jq -r .HCP_Consul_token.value output.json)
    export NOMAD_ADDR=$(jq -r .Primary_Nomad.value output.json)
}

function setup-nomad-acl {
    vault kv get -field=nomad_acls nomad/bootstrap > nomad_acls.json
    export NOMAD_TOKEN=$(jq -r .SecretID nomad_acls.json)
    export NOMAD_ADDR=$(jq -r .Primary_Nomad.value output.json)
}

setup-vault
setup-consul
setup-nomad
