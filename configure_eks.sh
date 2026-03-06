aws eks --region eu-west-2 update-kubeconfig --name guystack1-eks
# arn:aws:eks:eu-west-2:958215610051:cluster/guystack1-eks

kubectl config get-contexts


kubectl get secret consul-ent-license -n consul -o jsonpath='{.data.key}' | base64 -d ; echo

kubectl create namespace consul

kubectl create secret generic consul-bootstrap-token --from-literal token=Consul43v3r -n consul

kubectl create secret generic consul-ent-license --namespace consul --from-file=key=/Users/guybarros/Hashicorp/consul.hclic --context $dc1

consul-k8s install -f consul-dc1.yaml