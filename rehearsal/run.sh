#!/usr/bin/env bash
# k8snyumon ハンズオン H1・H3〜H9 のリハーサル（devcontainer の中で実行）
# 出力は results/ に回ごとに残す。失敗しても止めずに最後まで流す。
set -u
cd "$(dirname "$0")/.."
OUT=results; mkdir -p $OUT
ST=rehearsal/stages
log() { echo; echo "===== $* ====="; }
run() { echo "\$ $*"; timeout 300 bash -c "$*" 2>&1; echo "[exit $?]"; }
waitp() { sleep "${1:-10}"; }
gw_until() { local want="$1"; local t0=$(date +%s); for i in $(seq 1 60); do if curl -s -m 3 localhost:8080/ | grep -q "$want"; then echo "[Gateway] '$want' が出るまで $(( $(date +%s)-t0 ))秒"; return; fi; sleep 1; done; echo "[Gateway] 60秒待っても '$want' が出ない"; }
free_mem() { echo "--- free -m"; free -m; echo "--- docker stats"; docker stats --no-stream --format '{{.Name}} {{.MemUsage}} {{.CPUPerc}}'; }

# ---------------- H1
{
log H1 版
run docker version --format "'{{.Server.Version}}'"
run kubectl version --client
run kind version
nproc; free -m
log H1 クラスターを作る
start=$(date +%s)
run kind create cluster --config kind-config.yaml
echo "所要: $(( $(date +%s) - start ))秒"
run kubectl config current-context
run kubectl get nodes
run kubectl wait --for=condition=Ready nodes --all --timeout=180s
run kubectl get nodes -o wide
log H1 失敗：もう一度作る
run kind create cluster --config kind-config.yaml
free_mem
} > $OUT/H1.txt

# ---------------- H3
{
cp $ST/H3/pod.yaml manifests/
log H3 dry-run と apply
run kubectl apply -f manifests/pod.yaml --dry-run=server
run kubectl apply -f manifests/pod.yaml
run kubectl wait --for=condition=Ready pod/hitokoto --timeout=180s
run kubectl get pods -o wide
run kubectl describe pod hitokoto
run kubectl logs hitokoto
log H3 port-forward
(kubectl port-forward pod/hitokoto 8000:8000 >/tmp/pf.log 2>&1 &) ; waitp 4
run "curl -s localhost:8000/ | grep -E '<h1>|<footer>|banner'"
run curl -s localhost:8000/health
pkill -f "port-forward pod/hitokoto"
log H3 exec
run kubectl exec hitokoto -- sh -c "'hostname; whoami; id; env | grep -E \"DB_|APP_\"'"
run kubectl get pods --show-labels
log H3 失敗：タグ 9.9
sed -e 's/name: hitokoto$/name: hitokoto-bad/' -e 's/:1.0/:9.9/' manifests/pod.yaml | kubectl apply -f - 2>&1
waitp 25
run kubectl get pods
run "kubectl describe pod hitokoto-bad | sed -n '/Events:/,\$p'"
run kubectl delete pod hitokoto-bad hitokoto --wait=true
run kubectl get pods
} > $OUT/H3.txt

# ---------------- H4
{
sed 's/:1.1/:1.0/' $ST/H4/deployment.yaml > manifests/deployment.yaml
log H4 apply 1.0
run kubectl apply -f manifests/deployment.yaml
run kubectl rollout status deployment/hitokoto --timeout=180s
run kubectl get deploy,rs,pods -o wide
log H4 自己修復
P=$(kubectl get pods -l app=hitokoto -o name | head -1)
run kubectl delete $P
waitp 5
run kubectl get pods -o wide
log H4 スケール
run kubectl scale deployment hitokoto --replicas=5
run kubectl rollout status deployment/hitokoto --timeout=120s
run kubectl get pods -o wide
run kubectl scale deployment hitokoto --replicas=3
waitp 5
log H4 1.1 へ更新
cp $ST/H4/deployment.yaml manifests/deployment.yaml
run kubectl apply -f manifests/deployment.yaml
run kubectl rollout status deployment/hitokoto --timeout=180s
run kubectl get rs
run kubectl rollout history deployment/hitokoto
log H4 失敗：9.9
sed 's/:1.1/:9.9/' $ST/H4/deployment.yaml > manifests/deployment.yaml
run kubectl apply -f manifests/deployment.yaml
run kubectl rollout status deployment/hitokoto --timeout=40s
run kubectl get pods
run kubectl get rs
run kubectl rollout undo deployment/hitokoto
run kubectl rollout status deployment/hitokoto --timeout=180s
cp $ST/H4/deployment.yaml manifests/deployment.yaml
run kubectl apply -f manifests/deployment.yaml
run kubectl get pods
run kubectl rollout history deployment/hitokoto
} > $OUT/H4.txt

# ---------------- H5
{
cp $ST/H5/*.yaml manifests/
log H5 Service
run kubectl apply -f manifests/service.yaml
run kubectl get svc
run kubectl get endpoints hitokoto
run kubectl describe service hitokoto
run kubectl get endpointslices -l kubernetes.io/service-name=hitokoto
run kubectl apply -f manifests/web.yaml
run kubectl rollout status deployment/web --timeout=180s
run kubectl exec deploy/web -- curl -s http://hitokoto/health
for i in 1 2 3 4 5 6; do kubectl exec deploy/web -- curl -s http://hitokoto/ | grep -o 'Pod: [a-z0-9-]*'; done
log H5 NodePort
run kubectl apply -f manifests/service-nodeport.yaml
waitp 3
for i in 1 2 3 4; do curl -s localhost:30000/ | grep -o 'Pod: [a-z0-9-]*'; done
log H5 失敗：セレクター
sed 's/app: hitokoto$/app: hitokoto-app/' manifests/service.yaml | kubectl apply -f - 2>&1
run kubectl get endpoints hitokoto
run kubectl exec deploy/web -- curl -s -m 5 http://hitokoto/health
run kubectl apply -f manifests/service.yaml
run kubectl get endpoints hitokoto
log H5 Gateway の実装を入れる
start=$(date +%s)
run bash setup/install-gateway.sh
echo "所要: $(( $(date +%s) - start ))秒"
run kubectl get pods -n nginx-gateway -o wide
run kubectl get nginxproxy -n nginx-gateway -o yaml
log H5 Gateway と HTTPRoute
run kubectl apply -f manifests/gateway.yaml
run kubectl wait --for=condition=Programmed gateway/hitokoto-gateway --timeout=180s
run kubectl get gateway
run kubectl get svc -A
run kubectl get deploy,pods -l gateway.networking.k8s.io/gateway-name=hitokoto-gateway
run kubectl apply -f manifests/httproute.yaml
gw_until '<footer>'
run kubectl get httproute
run "kubectl describe httproute hitokoto | sed -n '/Status:/,\$p'"
waitp 5
run "curl -s localhost:8080/ | grep -E '<h1>|<footer>'"
run "curl -s localhost:8080/web | grep -i '<title>'"
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/web/"
log H5 失敗：backendRefs の名前
sed 's/- name: web$/- name: webb/' manifests/httproute.yaml | kubectl apply -f - 2>&1
waitp 5
run "kubectl describe httproute hitokoto | sed -n '/Status:/,\$p'"
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/web"
run kubectl apply -f manifests/httproute.yaml
free_mem
} > $OUT/H5.txt

# ---------------- H6
{
cp $ST/H6/configmap.yaml manifests/
cp $ST/H6/deployment.yaml manifests/
log H6 ConfigMap
run kubectl apply -f manifests/configmap.yaml
run kubectl apply -f manifests/deployment.yaml
run kubectl rollout status deployment/hitokoto --timeout=180s
gw_until 'ひとこと掲示板（開発）'
run "curl -s localhost:8080/ | grep -E '<h1>'"
log H6 値を変えても変わらない
sed -i 's/ひとこと掲示板（開発）/ひとこと掲示板（テスト）/' manifests/configmap.yaml
run kubectl apply -f manifests/configmap.yaml
waitp 5
run "curl -s localhost:8080/ | grep -E '<h1>'"
run kubectl rollout restart deployment/hitokoto
run kubectl rollout status deployment/hitokoto --timeout=180s
gw_until 'ひとこと掲示板（テスト）'
run "curl -s localhost:8080/ | grep -E '<h1>'"
log H6 ファイル
run kubectl exec deploy/hitokoto -- cat /config/notice.txt
sed -i 's/金曜日/土曜日/' manifests/configmap.yaml
run kubectl apply -f manifests/configmap.yaml
for s in 10 20 30 40 50 60 70 80 90; do sleep 10; echo "${s}秒後: $(kubectl exec deploy/hitokoto -- cat /config/notice.txt)"; done
cp $ST/H6/configmap.yaml manifests/
run kubectl apply -f manifests/configmap.yaml
log H6 Secret
run kubectl create secret generic db --from-literal=password=hitokoto-pass-123
run kubectl get secret db -o yaml
run "kubectl get secret db -o jsonpath='{.data.password}' | base64 -d; echo"
log H6 失敗：ConfigMap の名前
sed '0,/name: hitokoto-config$/s//name: hitokoto-confg/' manifests/deployment.yaml | kubectl apply -f - 2>&1
waitp 15
run kubectl get pods
P=$(kubectl get pods --no-headers | awk '/CreateContainerConfigError/{print $1; exit}')
[ -n "$P" ] && run "kubectl describe pod $P | sed -n '/Events:/,\$p'"
run kubectl apply -f manifests/deployment.yaml
run kubectl rollout status deployment/hitokoto --timeout=180s
} > $OUT/H6.txt

# ---------------- H7
{
log H7 StorageClass
run kubectl get storageclass
cp $ST/H7/*.yaml manifests/
log H7 PVC だけ
awk 'BEGIN{RS="---\n"} NR==1' manifests/db.yaml | kubectl apply -f - 2>&1
waitp 5
run kubectl get pvc
run kubectl get pv
log H7 db
run kubectl apply -f manifests/db.yaml
run kubectl rollout status deployment/db --timeout=240s
run kubectl get pvc,pv
run kubectl logs deploy/db --tail=5
log H7 掲示板をつなぐ
run kubectl apply -f manifests/configmap.yaml -f manifests/deployment.yaml
run kubectl rollout restart deployment/hitokoto
run kubectl rollout status deployment/hitokoto --timeout=180s
run "kubectl logs deploy/hitokoto | tail -5"
gw_until 'banner db'
run "curl -s localhost:8080/ | grep -E 'banner'"
run "curl -s -o /dev/null -w '%{http_code}\n' -X POST -d 'text=PVC のテスト' localhost:8080/"
sleep 2
for i in 1 2 3; do curl -s localhost:8080/ | grep -o -E 'PVC のテスト|Pod: [a-z0-9-]*' | tr '\n' ' '; echo; done
log H7 DB の Pod を消す
run kubectl delete pod -l app=db
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/"
run kubectl rollout status deployment/db --timeout=240s
waitp 5
gw_until 'banner db'
run "curl -s localhost:8080/ | grep -o -E 'PVC のテスト|banner [a-z]*'"
free_mem
} > $OUT/H7.txt

# ---------------- H8
{
log H8 metrics-server
run bash setup/install-metrics-server.sh
waitp 60
run kubectl top nodes
run kubectl top pods
cp $ST/H8/*.yaml manifests/
log H8 安全な設定
run kubectl apply -f manifests/deployment.yaml
run kubectl rollout status deployment/hitokoto --timeout=180s
run kubectl get pods
run "kubectl describe deploy hitokoto | sed -n '/Containers:/,/Volumes:/p'"
log H8 失敗1：memory 32Mi
sed -e 's/memory: 256Mi/memory: 32Mi/' -e 's/memory: 128Mi/memory: 32Mi/' manifests/deployment.yaml | kubectl apply -f - 2>&1
waitp 40
run kubectl get pods
P=$(kubectl get pods -l app=hitokoto --no-headers | awk '/OOMKilled|CrashLoop|Error/{print $1; exit}')
[ -n "$P" ] && run "kubectl describe pod $P | sed -n '/State:/,/Ready:/p;/Limits:/,/Requests:/p'"
run kubectl apply -f manifests/deployment.yaml
run kubectl rollout status deployment/hitokoto --timeout=240s
log H8 失敗2：liveness /healthz
awk '/livenessProbe:/{f=1} f&&/path: \/health/{sub("/health","/healthz");f=0} {print}' manifests/deployment.yaml | kubectl apply -f - 2>&1
waitp 75
run kubectl get pods
P=$(kubectl get pods -l app=hitokoto --sort-by=.metadata.creationTimestamp --no-headers | tail -1 | awk '{print $1}')
run "kubectl describe pod $P | sed -n '/Events:/,\$p'"
run kubectl apply -f manifests/deployment.yaml
run kubectl rollout status deployment/hitokoto --timeout=240s
log H8 PodSecurity
run kubectl apply -f manifests/secure-namespace.yaml
run kubectl apply -f manifests/root-pod.yaml
run kubectl apply -f manifests/safe-pod.yaml
run kubectl wait --for=condition=Ready pod/safe-hitokoto -n secure --timeout=120s
run kubectl get pods -n secure
run kubectl exec -n secure safe-hitokoto -- id
free_mem
} > $OUT/H8.txt

# ---------------- H9
{
log H9 片付け
run kubectl delete -f manifests/ --ignore-not-found
run kubectl delete namespace secure --ignore-not-found
run kubectl get pvc,pv
run kubectl get all
run kind delete cluster --name hitokoto
run docker ps -a
run kind get clusters
} > $OUT/H9.txt
echo done
