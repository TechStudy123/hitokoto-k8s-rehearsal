#!/bin/bash
# k8snyumon v2 のリハーサル（devcontainer＝Codespaces と同じ環境の中で動かす。2026-11-15）
# rehearsal/v2/steps_h{N}.json を、前の回の完成（rehearsal/v2/H{N-1}/）から始めて、説明資料から抜き出した手順のとおりに実行する。
cd "$(dirname "$0")/../.."
mkdir -p results
command -v python3 >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq python3 >/dev/null; }   # devcontainer の base には python3 が無い（リハーサルの道具 rh.py のためだけに入れる）
{
  echo "== 版"; docker version --format '{{.Server.Version}}'; kubectl version --client; kind version; python3 --version
  kind create cluster --config kind-config.yaml
  kubectl get nodes
} > results/env.log 2>&1
for N in ${RH_HANDSON:-3}; do
  P=$((N-1))
  cp -r rehearsal/v2/H$P/manifests/. manifests/
  [ -f manifests/pod.yaml ] && kubectl apply -f manifests/pod.yaml && kubectl wait --for=condition=Ready pod/hitokoto --timeout=180s
  python3 rehearsal/v2/rh.py run rehearsal/v2/steps_h$N.json --os mac --work . --out results/h$N.json > results/h$N.log 2>&1
  echo "H$N exit $?" >> results/env.log
done
# 講義 3-3 の見本のための出力（kubectl diff の実際の行・undo の警告）
{
  echo '== diff（版だけ）'; sed -i 's/hitokoto:2\.1/hitokoto:2.0/' manifests/deployment.yaml; kubectl diff -f manifests/deployment.yaml; echo "rc=$?"
  echo '== diff（replicas も）'; sed -i 's/replicas: 3/replicas: 1/' manifests/deployment.yaml; kubectl diff -f manifests/deployment.yaml; echo "rc=$?"
  git checkout -- manifests/deployment.yaml 2>/dev/null; cp rehearsal/v2/H3/manifests/deployment.yaml manifests/
  echo '== explain'; kubectl explain deployment.spec.strategy; kubectl explain deployment.spec.strategi; echo "rc=$?"
  echo '== dry-run 古い apiVersion'; sed 's#apps/v1#extensions/v1beta1#' manifests/deployment.yaml > /tmp/old.yaml; kubectl apply -f /tmp/old.yaml --dry-run=server; echo "rc=$?"
  echo '== dry-run ok'; kubectl apply -f manifests/deployment.yaml --dry-run=server; echo "rc=$?"
  echo '== selector mismatch'; sed '0,/app: hitokoto/! s/        app: hitokoto/        app: web/' manifests/deployment.yaml > /tmp/mis.yaml; kubectl apply -f /tmp/mis.yaml --dry-run=server; echo "rc=$?"
  echo '== delete pod の表示'; kubectl delete $(kubectl get pods -o name | head -n 1); echo "rc=$?"
  echo '== undo の表示（stderr も）'; kubectl rollout undo deployment/hitokoto 2>&1; echo "rc=$?"
  echo '== history'; kubectl rollout history deployment/hitokoto
  echo '== get pods -o wide'; kubectl get pods -o wide
} > results/extra.log 2>&1
kind delete cluster --name hitokoto >> results/env.log 2>&1
exit 0
