# Easy set up WordPress development with docker environment

### Notice:This scripts needs SSH connection to Bitbucket. If you didn't, set it up first.
### 注意：当該スクリプトはBitbucketへのSSH接続が必要です。下記のURLより登録してください。
`https://bitbucket.org/account/user/{user_name}/ssh-keys/`


## How to install
1. Clone project repository first.
1. Open command line and move to project root directory.
1. Run `git archive --remote=git@bitbucket.org:lig-admin/lig-wordpress-docker.git master | tar -x` 

## Set up Wordpress develop environment
1. Set `docker.env` up for your project first.
1. Open command line and move to project root directory.
1. Run `bash scripts/init_project.sh`.
1. It need to type Wordpress theme name for the project.

### That's all!! Enjoy depelopment!!

## Install LIG private plugins
You can get LIG private plugins with `bash scripts/install-private-plugin.sh {slug}` command.
Currently we're providing these plugins.
* lig-contact-form
* sns-count
* post-ranking

## インストール方法
1. まず、案件リポジトリをクローンします
1. コマンドラインを開き、プロジェクトディレクトリに移動します
1. `git archive --remote=git@bitbucket.org:lig-admin/lig-wordpress-docker.git master | tar -x` を実行します

## WordPress開発環境を作る
1.  `docker.env` を設定
1. コマンドラインを開き、プロジェクトディレクトリに移動します
1.  `bash scripts/init_project.sh` を実行します
1. テーマ名の入力を求められるので入力します

### これで完了です！

## LIG独自プラグインのインストール
`bash scripts/install-private-plugin.sh {slug}` コマンドを実行してください
現在、下記のプラグインが利用可能です
* lig-contact-form
* sns-count
* post-ranking

