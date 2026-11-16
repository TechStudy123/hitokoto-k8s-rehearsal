# hitokoto-team（チームの掲示板のマニフェスト）

ひとこと掲示板を、検証（staging）と本番（prod）で動かすためのマニフェストです。

## 読む順番
1. この README
2. `base/kustomization.yaml`（共通の部分の一覧）
3. `overlays/<環境>/kustomization.yaml`（環境ごとの違い）
4. `kubectl kustomize overlays/<環境>` で最終の YAML を出して読む
5. `kubectl diff -k overlays/<環境>` で違いを確かめてから `kubectl apply -k overlays/<環境>`

## 動かす前に用意するもの
- Secret `team-secret`（キー `DB_PASSWORD`）。値はチームの決まりに従って、`kubectl create secret` で作る（このリポジトリには入れない）。
