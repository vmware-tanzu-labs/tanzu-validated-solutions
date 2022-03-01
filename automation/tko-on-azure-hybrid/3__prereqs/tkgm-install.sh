tanzu plugin install --local tanzu/cli all
tanzu plugin list
tanzu management-cluster create --file config.yaml -v 9
kubectl apply -f pinniped-annotate.yaml
kubectl delete job -n pinniped-supervisor pinniped-post-deploy-job