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
  mkdir -p setup && cp -r rehearsal/v2/setup/. setup/ 2>/dev/null
  cp -r rehearsal/v2/hitokoto-team . 2>/dev/null
  if [ -f rehearsal/v2/restore_h$N.sh ]; then bash rehearsal/v2/restore_h$N.sh > results/restore_h$N.log 2>&1
  else [ -f manifests/pod.yaml ] && kubectl apply -f manifests/pod.yaml && kubectl wait --for=condition=Ready pod/hitokoto --timeout=180s; fi
  python3 rehearsal/v2/rh.py run rehearsal/v2/steps_h$N.json --os mac --work . --out results/h$N.json > results/h$N.log 2>&1
  echo "H$N exit $?" >> results/env.log
done
# 回ごとの追加の出力（あれば rehearsal/v2/extra_h{N}.sh。資料に書く表示を確かめるため）
for N in ${RH_HANDSON:-3}; do
  [ -f rehearsal/v2/extra_h$N.sh ] && bash rehearsal/v2/extra_h$N.sh > results/extra_h$N.log 2>&1
done
kind delete cluster --name hitokoto >> results/env.log 2>&1
exit 0
