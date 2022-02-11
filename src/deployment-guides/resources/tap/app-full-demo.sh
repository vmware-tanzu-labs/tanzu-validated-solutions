
<!-- /* cSpell:disable */ -->
#!/bin/bash

########################
# include the magic
########################
. demo-magic.sh

########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=15

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

# hide the evidence
clear


DEMO_PROMPT="${GREEN}➜ TAP ${CYAN}\W "

p "show all tap clusters "
pei "kubectl config get-contexts"

p "login to build cluster"
read -p "Enter build cluster context : " build_context
pei "kubectl config use-context ${build_context}"

p "Show Tanzu Application Platform(TAP) Build cluster Packages "

pei "tanzu package installed list -A"

p "Enter App Name "
read -p "App Name: " app_name

p "Enter App git url "
read -p "Git App Url: " git_app_url
  
echo


p "List apps workloads "
pei "tanzu apps workload list"

p "Delete all existing app workloads "
pei "tanzu apps workload delete --all"
echo

p "List apps workloads "
pei "tanzu apps workload list"
echo

p "Create ${app_name}  workload config yaml"
pei "tanzu apps workload create ${app_name} --git-repo ${git_app_url} --git-branch main --git-tag tap-1.0  --type web --label app.kubernetes.io/part-of=${app_name} --yes --dry-run"
echo

p "Execute ${app_name}  workload "
pei "tanzu apps workload create ${app_name} --git-repo ${git_app_url} --git-branch main --git-tag tap-1.0 --type web --label app.kubernetes.io/part-of=${app_name} --yes"
echo

p " ${app_name} deploy logs "
pei "tanzu apps workload tail ${app_name} --since 10m --timestamp"
echo

clear

p "List apps workloads "
pei "tanzu apps workload list"
echo

p " ${app_name} workload details  "
pei "tanzu apps workload get ${app_name}"

p " Generate ${app_name} delivery yaml "
pei "kubectl get deliverables ${app_name} -o yaml |  yq 'del(.status)'  | yq 'del(.metadata.ownerReferences)' | yq 'del(.metadata.resourceVersion)' | yq 'del(.metadata.uid)' >  ${app_name}-delivery.yaml"
                                                                                                                                                                                                                                          

p "show all tap clusters "
pei "kubectl config get-contexts"

p "login to Run cluster"
read -p "Enter build cluster context : " run_context
pei "kubectl config use-context ${run_context}"

p "Show Tanzu Application Platform(TAP) Run cluster Packages "
pei "tanzu package installed list -A"

p "check existing app  status"
pei "kubectl get deliverables ${app_name}"

p "delete already existing app"
pei "kubectl delete deliverables ${app_name}"

p "deploy ${app_name} deliverable into run cluster"
pei "kubectl apply -f ${app_name}-delivery.yaml"


p "check app status"
pei "kubectl get deliverables ${app_name}"

p "get app url"
pei "kubectl get all -A | grep route.serving.knative"


p "show all tap clusters "
pei "kubectl config get-contexts"

p "login to ui cluster"
read -p "Enter build cluster context : " ui_context
pei "kubectl config use-context ${ui_context}"


p "Show Tanzu Application Platform(TAP) UI cluster Packages "

pei "tanzu package installed list -A"

p "open tap-gui url and register entiry app. Provide app catelog_info.yaml path for register entiry into tap-gui.  "

<!-- /* cSpell:enable */ -->
                                                                                                                                                                                                     133,0-1       Bot
