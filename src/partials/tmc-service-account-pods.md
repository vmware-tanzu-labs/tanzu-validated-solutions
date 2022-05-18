# Allow TMC-created service accounts to create `Pod`s

> [Source](https://www.unknownfault.com/posts/podsecuritypolicy-unable-to-admit-pod/)

Tanzu Kubernetes Clusters come with a `vmware-system-privileged` `PodSecurityPolicy` (PSP) that prevents `Pod`s from being scheduled except by service accounts that are bound to this PSP by way of a namespaced `RoleBinding` or a cluster-wide `ClusterRoleBinding`. Tanzu Mission Control allows you to create service accounts for packages installed through it. However, because these accounts are not bound to this PSP, `Pod`s provisioned by these packages never get scheduled, causing TMC to time out during the installation.

As a workaround, create a `ClusterRoleBinding` allowing any authenticated service accounts to access the `vmware-system-privileged` PodSecurityPolicy:

```sh
kubectl apply -f <<-EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: administrator-cluster-role-binding
roleRef:
  kind: ClusterRole
  name: psp:vmware-system-privileged
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: Group
  name: system:authenticated
  apiGroup: rbac.authorization.k8s.io
EOF
```

If this is too permissive, you can also create a namespace into which your package will be installed, then use a `RoleBinding` to bind the namespace's `default` service account to this PSP:

```sh
kubectl create ns package-namespace &&
  kubectl apply -f <<-EOF
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rolebinding-cluster-user-administrator
  namespace: package-namespace
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: default
EOF
```

Note that you'll need to provide the namespace and service account when installing the package. This is demonstrated in the image below.

![](./img/tmc-service-account-pods/image110.png)

If you are not able to provide the name of a service account in advance, list the service accounts in the namespace with `kubectl get sa -n $NAMESPACE`, select the most recently created service account, then run the commands above, replacing `default` with the service account you selected.
