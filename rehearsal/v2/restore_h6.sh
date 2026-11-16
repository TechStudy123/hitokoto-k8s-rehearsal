# H6 の始め（H5 の完成。Secret は kubectl create で作る）
kubectl delete pod hitokoto web --ignore-not-found
kubectl create secret generic db-secret --from-literal=POSTGRES_PASSWORD=hitokoto-pass 2>/dev/null || true
kubectl apply -f manifests/configmap.yaml -f manifests/deployment.yaml -f manifests/service.yaml
kubectl rollout status deployment/hitokoto --timeout=180s
