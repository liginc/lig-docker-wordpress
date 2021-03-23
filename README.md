# LIG WordPress Docker Files

**Repository URI:** https://github.com/liginc/lig-docker-wordpress
**Contributors:** LIG inc  
**Requires at least:** docker engine 20.10
**Version:** 0.1 
**License:** GPLv2 or later  
**License URI:** http://www.gnu.org/licenses/gpl-2.0.html 

## Description

Apache+PHP+MySQLによるWordPress開発用Dockerファイル  

## Copyright

LIG WordPress Docker Files, Copyright 2019 LIG inc

LIG WordPress Docker Files is distributed under the terms of the GNU GPL.

LIG WordPress Docker Files bundles the following third-party resources:

_s, Copyright 2015-2018 Automattic, Inc. 

**License:** GPLv2 or later
Source: https://github.com/Automattic/_s/

normalize.css, Copyright 2012-2016 Nicolas Gallagher and Jonathan Neal

**License:** MIT
Source: https://necolas.github.io/normalize.css/

--- 

# Docker

## Environment Setup

1. Copy `.env-sample` to `.env`.
1. Set up `.env`

## Environment Variables

**PHP_VER:** PHPバージョン（8.0, 7.4, 7.3）
**MYSQL_VER:** PHPバージョン（8.0, 5.7, 5.6） 
**MYSQL_ROOT_PASSWORD:** WordPressをインストールするデータベースのユーザーパスワード  
**MYSQL_PASSWORD:**  
**MYSQL_DATABASE:** WordPressをインストールするデータベース名 
**MYSQL_USER:** WordPressをインストールするデータベースのユーザー名 
**SQL_DUMP_DATA:** コンテナ起動時にロードされるSQLファイル（.gzを推奨） 
**WP_VERSION:** インストールするWordPressのバージョン 
**WP_URL:** 初回起動時にWP_SITEURL、WP_HOMEに設定されるURL
**WP_ROOT:** WordPressがインストールされるdocker上の絶対パス 
**WP_DB_PREFIX:** 初回起動時に設定されるWordPressがインストールされるテーブルのプリフィックス 
**WP_ADMIN_USER:** 初回起動時に設定されるWordPressの管理者ユーザー名 
**WP_ADMIN_PASSWORD:** 初回起動時に設定されるWordPressの管理者ユーザーパスワード 
**WP_ADMIN_EMAIL:** 初回起動時に設定されるWordPressの管理者ユーザーemailアドレス 
**WP_INSTALL_PLUGINS:** 初回起動時にインストールされるプラグイン（半角スペースで複数設定できる） 
**WP_ACTIVATE_PLUGINS:** 初回起動時に有効化されるプラグイン（半角スペースで複数設定できる）
**WP_THEME_NAME:** 使用するテーマのディレクトリ名 

## Commands

### docker-compose build

`docker-compose.yml`と`.env`の設定に基づきdockerイメージを作成する

### docker-compose up

コンテナを作成、起動する

### npm run sqldump

`bash scripts/mysqldump.sh`を実行する

コンテナ削除時にSQLの内容が消失してしまう為、保存が必要な変更がある場合は当該コマンドを実行する

## Note

### Debugログ 
初回起動時に`wp-config.php`にデバッグ用の定数が設定される

#### /wp/wp-content/debug.log 
apacheのデバッグログ

#### /wp/wp-content/uploads/mw-wp-form_uploads/mw-wp-form-debug.log
MW WP Form利用時にメールの送信をキャンセルし、送信内容のログを残す


