#!/bin/sh

cd $(cd $(dirname $0); pwd)
cd ../

git archive --remote=git@bitbucket.org:lig-admin/lig-wordpress-plugin-${1}.git master | tar -x -C "wp/wp-content/plugins"

# Remove .gitignore
find wp/wp-content/plugins/**/* -name "*.gitignore" -exec rm {} \;