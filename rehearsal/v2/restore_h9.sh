# H9 の始め（H8 の続き。Gateway の種類が無いと manifests/ をまとめて消すときにエラーになるので、種類だけ入れる）
kubectl config set-context --current --namespace=default
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml >/dev/null
