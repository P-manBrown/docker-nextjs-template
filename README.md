# Docker-Next.jsテンプレートリポジトリ

Docker上のNext.js(TypeScript・Yarn v3)環境を構築するためのテンプレートリポジトリです。  

— **目次** —

- [概要](#概要)
  - [パッケージ](#パッケージ)
  - [コミット](#コミット)
  - [ブランチ](#ブランチ)
  - [プロジェクト用の設定](#プロジェクト用の設定)
- [使用方法](#使用方法)

## 概要

### パッケージ

プロジェクト作成時より以下のパッケージが使用できます。  

- commitlint
- ESLint
- Jest
- Lefthook
- markdownlint-cli
- Prettier
- Storybook
- Tailwind CSS
- Testing Library

Lefthookをホストで使用するには別途ローカルにインストールする必要があります。  
[【evilmartians/lefthook】Install lefthook](https://tinyurl.com/yc7mhabe)を参考にインストールしてください。  

Dockerベースイメージおよびパッケージが更新可能な場合にDependabotによりプルリクエストが発行されます。  

### コミット

コミットメッセージは[COMMIT_CONVENTION.md](https://tinyurl.com/git-commit-convention)に基づいて作成します。  
これを容易にするため、[.gitmessage](https://tinyurl.com/gitmessage)をコミットメッセージのテンプレートとして使用します。  

### ブランチ

マージされたリモートブランチは自動で削除されるように設定されます。  

### プロジェクト用の設定

プロジェクト名に`frontend`という文言を含めると以下の機能が有効になります。  

- ブランチの作成  
  `develop`ブランチが作成されます。  
- `main`と`develop`が保護ブランチになる  
  上記ブランチへ`marge`する際にプルリクエストに対し1件以上の承認が必要になります。  
  また新しいコミットが`push`されたときに古いプルリクエストの承認が却下されるようになります。  
- `host.docker.internal`に関する設定追加  
  [compose.yml](compose.yml)の`extra_hosts`の設定が追加されます。  
  （プロジェクト名に`frontend`が含まれていない場合には`extra_hosts`は削除されます。）  
- Lefthookの実行コマンド追加  
  [lefthook.yml](lefthook.yml)の`protect-branch`が有効になります。  
  （プロジェクト名に`frontend`が含まれていない場合には`protect-branch`は削除されます。）  

## 使用方法

まずこのリポジトリをテンプレートとして新規リポジトリを作成します。  

```terminal
gh repo create <新規リポジトリ名> --public --template P-manBrown/docker-nextjs-template
```

次のコマンドを実行して作成したリポジトリをローカルにクローンします。  

```terminal
git clone --recurse-submodules <リポジトリ URL or SSH key>
```

プロジェクトルートに移動します。  

```terminal
cd <作成されたディレクトリ>
```

プロジェクト作成の準備をするために次のコマンドを実行します。  

```terminal
bash setup/scripts/prepare-create-pj.sh
```

プロジェクトを作成するために以下の手順を実行します。  

<details>
  <summary>「Dev Containers」を使用する場合（クリックして展開）</summary>

`.devcontainer/environment/gh-token.env`を書き換えます。

ここで使用するPersonal Access Tokenには以下のスコープが必要です。  

- repo
- read:org

書き換え後「Dev Containers」を起動します。  
コマンドパレットで`Dev Containers: Reopen in Container`を実行します。  
起動完了後コンテナ内で次のコマンドを実行してNext.jsアプリケーションを作成します。  

```terminal
bash setup/scripts/create-pj.sh
```

</details>

<details>
  <summary>「Dev Containers」を使用しない場合（クリックして展開）</summary>

LefthookをDockerに対応させるため[lefthook-local.yml](setup/config/lefthook-local.yml)をプロジェクトルートに移動します。  

```terminal
mv setup/config/lefthook-local.yml ./
```

次のコマンドを実行してNext.jsアプリケーションを作成します。  

```terminal
docker compose run --rm --no-deps api bash setup/scripts/create-pj.sh
```

</details>

次に`README.md`を作成します。  

作成後に次のコマンドを実行して「Initial commit」を再作成します。  

```terminal
bash setup/scripts/initial-commit.sh
```
