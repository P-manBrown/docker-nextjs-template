# Docker-Next.jsのテンプレートリポジトリ

## 目次

- [Docker-Next.jsのテンプレートリポジトリ](#docker-nextjsのテンプレートリポジトリ)
  - [目次](#目次)
  - [概要](#概要)
    - [パッケージ](#パッケージ)
    - [コミット](#コミット)
    - [プロジェクト用の設定](#プロジェクト用の設定)
  - [使用方法](#使用方法)

## 概要

Docker上のNext.js(TypeScript・Yarn v3)環境を構築するためのテンプレートリポジトリです。  

### パッケージ

プロジェクト作成時より以下のツールが使用できます。  

- commitlint
- ESLint
- Jest
- Lefthook
- Prettier
- Storybook
- Tailwind CSS
- Testing Library

Node.js環境がない場合にLefthookをホスト上で使用するには別途ローカルにインストールする必要があります。  
[【evilmartians/lefthook】Install lefthook](https://github.com/evilmartians/lefthook/blob/master/docs/install.md)を参考にインストールしてください。  

### コミット

コミットメッセージは[COMMIT_CONVENTION.md](.github/commit/COMMIT_CONVENTION.md)に基づいて作成します。  
これを容易にするため[gitmessage.txt](.github/commit/gitmessage.txt)をコミットメッセージのテンプレートとして使用します。  

### プロジェクト用の設定

プロジェクト名に`frontend`という文言を含めると以下の機能が追加されます。  

- ブランチの作成と移動  
  `develop`ブランチが作成されプロジェクト作成完了までの処理が`develop`ブランチで実行されます。  
- `main`と`develop`が保護ブランチになる  
  上記ブランチへ`marge`する際にプルリクエストに対し1件以上の承認が必要になります。  
  また新しいコミットが`push`されたときに古いプルリクエストの承認が却下されるようになります。
- マージされたブランチの自動削除  
  マージされたリモートブランチが自動で削除されるようになります。  
- Lefthookの実行コマンド追加  
  `lefthook.yml`が[こちらの内容](./setup/settings/lefthook-project.yml)に変更されます。  
- Dockerのベースイメージやパッケージの自動更新  
  Dependabotが有効になり上記が更新可能な場合に更新のプルリクエストが平日3:00に自動発行されます。  

## 使用方法

まずこのリポジトリをテンプレートとして新規リポジトリを作成します。  

```terminal
gh repo create <新規リポジトリ名> --public --template P-manBrown/docker-nextjs-template
```

以下のコマンドを実行して作成したリポジトリをローカルにクローンします。  

<details>
  <summary>gitコマンドの場合</summary>

```terminal
git clone <URL or SSH key>
```

</details>

<details>
  <summary>ghコマンドの場合</summary>

```terminal
gh repo clone <GitHubユーザー名/新規リポジトリ名>
```

</details>

プロジェクトルートに移動します。  

```terminal
cd <作成されたディレクトリ>
```

プロジェクト作成の準備するために以下のコマンドを実行します。  

<details>
  <summary>Zshの場合</summary>

```terminal
zsh setup/scripts/prepare-create-pj.sh
```

</details>

<details>
  <summary>Bashの場合</summary>

```terminal
bash setup/scripts/prepare-create-pj.sh
```

</details>

プロジェクトを作成するために以下の手順を実行します。  

<details>
  <summary>「Dev Containers」を使用する場合</summary>

まず`.devcontainer/secrets/github-token.txt`を書き換えます。  
ここで使用するPersonal Access Tokenには以下のスコープが必要です。  

- repo
- read:org

書き換え後「Dev Containers」を起動します。  
コマンドパレットで`Dev Containers: Reopen in Container`を実行します。  
起動完了後プロジェクトを作成するためにコンテナ内で次のコマンドを実行します。  

```terminal
bash setup/scripts/create-pj.sh
```

</details>

<details>
  <summary>「Dev Containers」を使用しない場合</summary>

プロジェクトを作成するために以下のコマンドを実行します。  

```terminal
docker compose run --rm --no-deps frontend bash setup/scripts/create-pj.sh
```

</details>

`./.gitignore`および`./package.json`の内容を整理します。  

最後にNext.jsが正常に起動できるか確認します。  

<details>
  <summary>「Dev Containers」を使用している場合</summary>

```terminal
yarn dev
```

</details>

<details>
  <summary>「Dev Containers」を使用していない場合</summary>

```terminal
docker compose up
```

</details>
