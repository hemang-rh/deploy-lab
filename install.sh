git clone https://github.com/rhoai-mlops/deploy-lab.git

## IMPORTANT: Scale worker nodes (4 worker nodes per user)
# IMPORTANT Change the number of users and the cluster domain

## 1: Install GitOps Operator and Instance
helm upgrade --install ml500-gitops gitops --namespace ml500 --create-namespace

## 2: Go to Operators directory
helm dependency build

## 3. Install Operators (this will be in an AppSet)
helm upgrade --install ml500-operators operators --namespace ml500 --create-namespace

# IMPORTANT: Go to operator hub and manually install stuck operators

## 4
oc apply -f datasciencecluster.yaml


## 5
helm upgrade --install ml500-base charts/ --namespace ml500 --create-namespace


# 6. Patch OAuth to point to ML500 htpasswd
oc patch --type=merge OAuth/cluster -p '{"spec": {"identityProviders": [{"name": "Students", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd-ml500"}}}, {"name": "htpasswd_provider", "type": "HTPasswd", "mappingMethod": "claim", "htpasswd": {"fileData": {"name": "htpasswd"}}}]}}'

#oc patch --type=merge DataScienceCluster/default-dsc -p '{"spec": {"components": {"trustyai": {"managementState": "Managed", "devFlags": {"manifests": [{"contextDir": "config", "sourcePath": "", "uri": "https://api.github.com/repos/trustyai-explainability/trustyai-service-operator-ci/tarball/service-acca8f52f3f163444b2fc68003af5cae13f04762"}]}}}}}'

# 7
oc patch config.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

# 8
# Make ArgoCD cluster wide
attendees=`grep attendees charts/values.yaml | cut -d':' -f2`
 for ((i=0; i<=$attendees; i++))
 do
   if [ $i -eq 1 ]; then
     NS="user$i-toolings"
   else
     NS+="$var,user$i-toolings"
   fi
 done
 oc -n openshift-gitops-operator patch subscriptions.operators.coreos.com/openshift-gitops-operator --type=json \
         -p '[{"op":"'add'","path":"/spec/config/env", "value":[{"name": "DISABLE_DEFAULT_ARGOCD_INSTANCE", "value":"true"}] },{"op":"'add'","path":"/spec/config/env/1","value":{"name": "ARGOCD_CLUSTER_CONFIG_NAMESPACES", "value":"'${NS}'"}}]'

# 9 Delete htpasswd Identity provider and only keep Students identity provider

# 10 Remove resources from trusty and model registry operator deployments
# workloads -> deployments -> redhat-ods-applications -> (trustyai, model-registry) Remove resource limit values
