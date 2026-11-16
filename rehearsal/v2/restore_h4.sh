# H4 の始め（H3 の完成の Deployment を作り直す）
kubectl delete pod hitokoto web --ignore-not-found
kubectl apply -f manifests/deployment.yaml
kubectl rollout status deployment/hitokoto --timeout=180s
