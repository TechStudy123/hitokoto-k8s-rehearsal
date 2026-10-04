#!/usr/bin/env bash
# Gateway API の実装（NGINX Gateway Fabric）を入れる（第5章・ハンズオン5）
set -euo pipefail
GATEWAY_API=v1.6.1
NGF=v2.7.2
# 1. Gateway API の決まりごと（CRD）
kubectl apply --server-side -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API}/standard-install.yaml"
# 2. 実装の CRD と本体
kubectl apply --server-side -f "https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/${NGF}/deploy/crds.yaml"
kubectl apply -f "https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/${NGF}/deploy/nodeport/deploy.yaml"
# 3. 入り口のポートを 30080 に決める（kind の設定で 8080 として外に出してある）
kubectl patch nginxproxy nginx-gateway-proxy-config -n nginx-gateway --type merge \
  -p '{"spec":{"kubernetes":{"service":{"externalTrafficPolicy":"Cluster","nodePorts":[{"port":30080,"listenerPort":80}]}}}}'
kubectl wait --for=condition=Available deployment/nginx-gateway -n nginx-gateway --timeout=180s
kubectl get gatewayclass
