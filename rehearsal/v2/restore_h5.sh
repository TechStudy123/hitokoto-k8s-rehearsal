# H5 の始め
kubectl delete pod hitokoto web --ignore-not-found
kubectl apply -f manifests/deployment.yaml -f manifests/service.yaml
kubectl rollout status deployment/hitokoto --timeout=180s
