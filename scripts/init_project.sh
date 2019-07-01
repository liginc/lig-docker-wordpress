#!/bin/sh

cd $(cd $(dirname $0); pwd)
cd ../

# Require docker.env
source docker.env

# Define theme name
if [ -n "$WP_THEME_NAME" ]; then
    echo "Template name is already defined(${WP_THEME_NAME})"
else
    while true;do
        echo -e "\033[0;33;1m[ Enter template name. ]\033[0;39m"
        read WP_THEME_NAME
        WP_THEME_NAME=$(echo ${WP_THEME_NAME} | sed -e "s/[^0-9a-zA-Z\-]//g")
        if [ -n "$WP_THEME_NAME" ]; then
        break;
        fi
    done
    echo -e "\nWP_THEME_NAME=${WP_THEME_NAME}" >> docker.env
    echo -e "\n!/wp/wp-content/themes/${WP_THEME_NAME}/" >> .gitignore
fi

# Define php version
if [ -n "$PHP_VER" ]; then
    echo "PHP VERSION is already defined(${PHP_VER})"
else
    echo -e "\033[0;33;1m[ Enter PHP Ver.(If type nothing, it'll be 7.2 ) ]\033[0;39m"
    read PHP_VER
    if [ -z "$PHP_VER" ]; then
        PHP_VER=7.2
        echo 7.2
    fi
    echo -e "\nPHP_VER=${PHP_VER}" >> docker.env
fi

# Define WordPress version
if [ -n "$WP_VERSION" ]; then
    echo "WordPress VERSION is already defined(${WP_VERSION})"
else
    echo -e "\033[0;33;1m[ Enter WordPress Ver.(If type nothing, it'll be latest version ) ]\033[0;39m"
    read WP_VERSION
    if [ -z "$WP_VERSION" ]; then
        WP_VERSION=latest
        echo WP_VERSION=laetst
    fi
    echo -e "\nWP_VERSION=${WP_VERSION}" >> docker.env
fi

# Make directories
if [ ! -e "wp/wp-content/themes/${WP_THEME_NAME}" ]; then
    mkdir -p wp/wp-content/themes/${WP_THEME_NAME}
fi
if [ ! -e "wp/wp-content/plugins" ]; then
    mkdir -p wp/wp-content/plugins
fi

# Install Laravel-mix from github
if [ -e webpack.mix.js ]; then
    echo "It seems that Laravel-mix is already installed"
else
    echo "Install Laravel-mix"
    wget https://github.com/dsktschy/laravel-mix-boilerplate/archive/wordpress.tar.gz
    if [ $? -ne 0 ]; then
        echo "Failed to download Laravelmix"
        exit 1
    fi

    tar -xf wordpress.tar.gz
    if [ $? -eq 0 ]; then

        README=$(cat laravel-mix-boilerplate-wordpress/README.md <(echo "\n\n------\n\n") README.md)
        echo -e ${README} > README.md

        rm -f wordpress.tar.gz
        rm -f laravel-mix-boilerplate-wordpress/README.md
        rm -f laravel-mix-boilerplate-wordpress/.gitignore
        rm -Rf laravel-mix-boilerplate-wordpress/.git

        shopt -s dotglob
        mv laravel-mix-boilerplate-wordpress/* ./
        shopt -u dotglob

        mv resources/themes/input-theme-name resources/themes/${WP_THEME_NAME}

        rm -Rf laravel-mix-boilerplate-wordpress

        grep -l "= 'input-theme-name'" webpack.mix.js | xargs sed -i.bak -e "s|= 'input-theme-name'|= '${WP_THEME_NAME}'|g"
        grep -l "wp-content\/themes" webpack.mix.js | xargs sed -i.bak -e "s|wp-content/themes|wp/wp-content/themes|g"

        mv wp-content/themes/input-theme-name/* "wp/wp-content/themes/${WP_THEME_NAME}"
        rm -Rf wp-content

        echo "Done installing Laravel-mix"
    fi
fi

# Install node modules and build
if [ -e "package.json" ] && $(which node > /dev/null 2>&1 && which npm > /dev/null 2>&1); then
    npm i
    npm run production
fi

# Install deploy-tools
#if [ -e "deploy-tools" ]; then
#    echo "It seems to deploy-tools already installed"
#else
#    echo "Install deploy-tools"
#    mkdir deploy-tools
#    git archive --remote=git@bitbucket.org:lig-admin/deploy-tools.git master | tar -x -C deploy-tools
#
#    mv deploy-tools/deploy.env deploy.env
#    mv deploy-tools/deploy.php wp/deploy.php
#
#    git archive --remote=git@bitbucket.org:lig-admin/lig-wordpress-plugins.git master | tar -x -C "wp/wp-content/plugins"
#    git archive --remote=git@bitbucket.org:lig-admin/lig-wordpress-template.git master | tar -x -C "wp/wp-content/themes/${WP_THEME_NAME}"
#
#    echo "Done installing deploy-tools"
#fi

# Remove .gitignore on child directory
find ./**/* -name "*.gitignore" -exec rm {} \;

echo "Build docker image"
docker-compose build --build-arg PHP_VER="php:${PHP_VER}-apache"
ps=$(docker ps)
if [ ${#ps} > 150 ]; then
echo "Docker container are already exist"
exit
#    docker rm -f $(docker ps -aq)
fi
docker-compose up
