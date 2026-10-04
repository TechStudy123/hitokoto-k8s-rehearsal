#!/usr/bin/env bash
# kubectl top を使えるようにする（第8章・ハンズオン8）
set -euo pipefail
METRICS_SERVER=v0.9.0
kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_SERVER}/components.yaml"
# kind のノードは自己署名の証明書なので、練習用に確認を省く（本番ではしない）
kubectl patch deployment metrics-server -n kube-system --type json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl rollout status deployment/metrics-server -n kube-system --timeout=180s
