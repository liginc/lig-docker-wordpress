#!/bin/bash

echo >&2 "Waiting MySQL to be up and running..."
wait-for-it.sh -t 0 mysql:3306
echo >&2 "MySQL database is now ready to handle connection."

# Delete wp-config
if [ -f ${WP_ROOT}/wp-config.php ]; then
	echo >&2 "wp-config.php was detected. Deleting..."
	rm -f ${WP_ROOT}/wp-config.php
fi

# Then initialize a local wp-config if not exists
if [ -f ${WP_ROOT}/wp-config.local.php ]; then
	echo >&2 "wp-config.local.php was detected. Skipping downloading Wordpress files..."
else
	echo >&2 "Downloading Wordpress files..."
	wp core download --path=${WP_ROOT} --allow-root --version=${WP_VERSION}
	echo >&2 "Setting up wp-config.php..."
	wp core config --path=${WP_ROOT} --allow-root \
		--dbname=${MYSQL_DATABASE} \
		--dbuser=root \
		--dbpass=${MYSQL_ROOT_PASSWORD} \
		--dbhost=mysql \
		--dbprefix=${WP_DB_PREFIX} \
		--skip-plugins \
		--skip-themes \
		--skip-salts \
		--skip-check \
		--extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_DISPLAY', true );
define( 'WP_DEBUG_LOG', true );
PHP
	mv ${WP_ROOT}/wp-config.php ${WP_ROOT}/wp-config.local.php
fi

# Make a symlink to wp-config
(cd ${WP_ROOT} && ln -s wp-config.local.php wp-config.php)

if $(wp core is-installed --path=${WP_ROOT} --allow-root); then
	echo >&2 "Wordpress seems to be installed."
else
	echo >&2 "Installing Wordpress..."
	# Install core
	wp core install --path=${WP_ROOT} --allow-root \
		--url=${WP_URL} \
		--title=wp \
		--admin_user=${WP_ADMIN_USER} \
		--admin_password=${WP_ADMIN_PASSWORD} \
		--admin_email=${WP_ADMIN_EMAIL} \
		--skip-email
    echo "Initialize WordPress"
	wp language core install ja --allow-root
	wp option update timezone_string 'Asia/Tokyo' --allow-root
	wp option update WPLANG 'ja' --allow-root
	wp option update blog_public '0' --allow-root
	wp option update default_ping_status 'closed' --allow-root
	wp option update default_comment_status 'closed' --allow-root
	wp comment delete 1 --force --allow-root
	wp post delete 1 2 3 4 --force --allow-root

    # Remove default installed plugins
    wp plugin delete akismet --allow-root
    wp plugin delete hello --allow-root

    # Install extra plugins specified by $WP_INSTALL_PLUGINS
    if [[ -z "${WP_INSTALL_PLUGINS}" ]]; then
        echo >&2 "env var \$WP_INSTALL_PLUGINS is empty - skipping installing extra plugins";
    else
        for TEMP_WP_PLUGIN in $WP_INSTALL_PLUGINS; do
            echo >&2 "Installing extra plugin ${TEMP_WP_PLUGIN}..."
            if ! $(wp plugin is-installed ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root); then
                wp plugin install ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root
            fi
        done
        unset "TEMP_WP_PLUGIN"
    fi
    wp plugin activate --all --allow-root
fi

# Activate theme
if $(wp theme is-installed twentynineteen --allow-root); then
    wp theme activate ${WP_THEME_NAME} --path=${WP_ROOT} --allow-root

    # Delete theme
    wp theme delete $(wp theme list --status=inactive --field=name --allow-root) --allow-root

    if ! $(wp core is-installed --path=${WP_ROOT} --allow-root); then
        echo >&2 "WARNING: It seems that wrong params was set to docker.env - press Ctrl+C now if this is an error!"
    fi
fi

envs=(
	MYSQL_ROOT_PASSWORD
	MYSQL_DATABASE
	WP_URL
	WP_ROOT
	WP_VERSION
	WP_DB_PREFIX
	WP_ADMIN_USER
	WP_ADMIN_PASSWORD
	WP_ADMIN_EMAIL
	WP_THEME_NAME
	WP_INSTALL_PLUGINS
)

# now that we're definitely done writing configuration, let's clear out the relevant envrionment variables (so that stray "phpinfo()" calls don't leak secrets from our code)
for e in "${envs[@]}"; do
	unset "$e"
done

echo >&2 "Wordpress initialization completed!"

exec "$@"