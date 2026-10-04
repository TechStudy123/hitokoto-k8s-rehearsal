# ひとこと掲示板を Kubernetes で動かす（hitokoto-k8s）

ハンズオンで使うリポジトリです。ブラウザから短いメッセージを書き込むと、一覧に表示される小さな Web アプリ（ひとこと掲示板）を、練習用の Kubernetes のクラスター（kind）で動かします。

アプリのイメージは公開済みの `ghcr.io/container-nyumon/hitokoto` を使います。**このリポジトリにはアプリのコードはありません。** マニフェスト（YAML）を `manifests/` に書いていきます。

## 中身

| ファイル | 役割 |
|---|---|
| `kind-config.yaml` | 練習用のクラスターの形（コントロールプレーン1台・ノード2台・外に出すポート） |
| `manifests/` | ハンズオンで書くマニフェストの置き場（最初は空） |
| `setup/install-gateway.sh` | Gateway API の実装を入れる（ハンズオン5） |
| `setup/install-metrics-server.sh` | `kubectl top` を使えるようにする（ハンズオン8） |
| `.devcontainer/` | Codespaces の設定（Docker・kubectl・kind が入る） |

## 使い方

1. 右上の **Use this template** → **Create a new repository** で、自分のリポジトリを作ります。
2. 受講環境に合わせて開きます。
   - **Codespaces（ブラウザだけ）**: 自分のリポジトリの **Code** → **Codespaces** → **Create codespace on main**
   - **自分の PC（Docker Desktop／WSL2＋Docker Engine）**: kubectl と kind を入れ、`git clone` で取ってきたフォルダでターミナルを開く
3. クラスターを作ります。

```bash
kind create cluster --config kind-config.yaml
kubectl get nodes
```

## アプリの設定（環境変数）

| 名前 | 意味 |
|---|---|
| `DB_HOST` | データベースの Service の名前。`none` にすると DB を使わない（必須） |
| `DB_PASSWORD` | データベースのパスワード |
| `APP_TITLE` | 見出しのタイトル（省略すると「ひとこと掲示板」） |

ポートは 8000、確認用のパスは `/health` です。画面の右下に、イメージの版と、表示した Pod の名前が出ます。

## 後片付け

```bash
kind delete cluster --name hitokoto
```

Codespaces を使った方は、Codespace を止めるか削除してください。
