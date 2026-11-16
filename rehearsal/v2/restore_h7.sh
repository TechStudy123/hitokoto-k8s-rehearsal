# H7 の始め（H6 の完成）
kubectl delete pod hitokoto web note --ignore-not-found
kubectl create secret generic db-secret --from-literal=POSTGRES_PASSWORD=hitokoto-pass 2>/dev/null || true
kubectl apply -f manifests/configmap.yaml -f manifests/pvc.yaml -f manifests/postgres.yaml -f manifests/deployment.yaml -f manifests/service.yaml
kubectl rollout status deployment/hitokoto --timeout=180s
