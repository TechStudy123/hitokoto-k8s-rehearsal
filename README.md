# ひとこと掲示板を Kubernetes で動かす（hitokoto-k8s）

講座「Kubernetes 入門 〜Pod・Deployment・Service を動かして理解する〜」のハンズオンで使うリポジトリです。ブラウザから短いメッセージを書き込むと一覧に表示される小さな Web アプリ（ひとこと掲示板）を、練習用の Kubernetes のクラスター（kind）で動かします。

アプリのイメージは公開済みの `ghcr.io/container-nyumon/hitokoto`（2.0・2.1）を使います。**このリポジトリにはアプリのコードはありません。** マニフェスト（YAML）を `manifests/` に書いていきます。

## 中身

| ファイル | 役割 |
|---|---|
| `kind-config.yaml` | 練習用のクラスターの形（本部1台・店舗2台・外に出すポート） |
| `manifests/` | ハンズオンで書くマニフェストの置き場（最初は空） |
| `setup/gateway-nodeport.yaml` | Gateway の入り口の番号を決める設定（ハンズオン4） |
| `setup/metrics-server-tls.json` | metrics-server を kind で動かすための設定（ハンズオン7。練習用） |
| `setup/team.yaml` | 本番役の区画と、見るだけの権限のユーザー役（ハンズオン8。会社では管理者が用意するもの） |
| `hitokoto-team/` | チームのリポジトリ役（Kustomize の base と overlays。ハンズオン8） |
| `broken/` | わざと壊した3つのアプリ（ハンズオン9） |
| `.devcontainer/` | Codespaces の設定（Docker・kubectl・kind が入る） |

## 使い方

1. 右上の **Use this template** → **Create a new repository** で、自分のアカウントにリポジトリ `hitokoto-k8s` を作ります。
2. 受講環境に合わせて開きます。
   - **Codespaces（ブラウザだけ）**: 自分のリポジトリの **Code** → **Codespaces** → **Create codespace on main**
   - **自分の PC**: kubectl と kind を入れ、`git clone` で取ってきたフォルダでターミナルを開く（ハンズオン0 の説明資料）
3. クラスターを作ります。

```
kind create cluster --config kind-config.yaml
kubectl get nodes
```

## アプリの設定（環境変数）

| 名前 | 意味 |
|---|---|
| `DB_HOST` | データベースの Service の名前。指定しなければデータベースを使わない（書き込みは Pod ごと・Pod を消すと消える） |
| `DB_PASSWORD` | データベースのパスワード |
| `APP_TITLE` | 見出しのタイトル（省略すると「ひとこと掲示板」） |

ポートは 8000、確認用のパスは `/health` です。画面のいちばん下に、イメージの版と、表示した Pod の名前が出ます。

## 後片付け

```
kind delete cluster --name hitokoto
```

Codespaces を使った方は、Codespace を止めるか削除してください（ハンズオン9）。
