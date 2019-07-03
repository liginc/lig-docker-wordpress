#!/bin/bash

echo >&2 "Waiting MySQL to be up and running..."
wait-for-it.sh -t 0 mysql:3306
echo >&2 "MySQL database is now ready to handle connection."

# Download and Install WordPress
if [ ! -f ${WP_ROOT}/wp-config.php ]; then
	echo >&2 "Downloading Wordpress files..."
	wp core download --path=${WP_ROOT} --allow-root --version=${WP_VERSION}

	echo >&2 "Setting up config file..."
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

    echo >&2 "Removing wp-config-sapmle.ph...p"
	rm -f ${WP_ROOT}/wp-config-sample.php

    # Init Project
    if [ ! -e ${SQL_DUMP_DATA} ]; then

        echo "There is no sql dump file"

        echo "Installing WordPress..."
        # Install core
        wp core install --path=${WP_ROOT} --allow-root \
            --url=${WP_URL} \
            --title=wp \
            --admin_user=${WP_ADMIN_USER} \
            --admin_password=${WP_ADMIN_PASSWORD} \
            --admin_email=${WP_ADMIN_EMAIL} \
            --skip-email

        echo >&2 "Installing Japanese language file..."
        wp language core install ja --allow-root

        echo "Setting up options..."
        wp option update timezone_string 'Asia/Tokyo' --allow-root
        wp option update WPLANG 'ja' --allow-root
        wp option update blog_public '0' --allow-root
        wp option update default_ping_status 'closed' --allow-root
        wp option update default_comment_status 'closed' --allow-root
        wp comment delete 1 --force --allow-root
        wp post delete 1 2 3 4 --force --allow-root

        # Install extra plugins specified by $WP_INSTALL_PLUGINS
        if [[ -z "${WP_INSTALL_PLUGINS}" ]]; then
            echo >&2 "env var \$WP_INSTALL_PLUGINS is empty - skipping installing extra plugins";
        else
            echo >&2 "Downloading extra plugins"
            for TEMP_WP_PLUGIN in $WP_INSTALL_PLUGINS; do
                echo >&2 "Installing extra plugin ${TEMP_WP_PLUGIN}..."
                if ! $(wp plugin is-installed ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root); then
                    wp plugin install ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root
                    echo >&2 "Activating plugins..."
                    wp plugin activate ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root
                fi
            done
            unset "TEMP_WP_PLUGIN"
        fi

        #Activate theme"
        if [[ -z "${WP_THEME_NAME}" ]] && [ -e ${WP_THEME_NAME} ]; then
            echo &>2 "Activating Theme..."
            wp theme activate ${WP_THEME_NAME} --path=${WP_ROOT} --allow-root
        fi
    else
        echo >&2 "The Project seems to be already started."

        echo >&2 "Installing Japanese language file..."
        wp language core install ja --allow-root

        # Install core
        echo >&2 "Installink WordPress..."
        wp core install --path=${WP_ROOT} --allow-root \
            --skip-email
    fi

    # Delete default plugins
    wp plugin delete akismet --allow-root
    wp plugin delete hello --allow-root

    # Delete Default theme
    rm -Rf ${WP_ROOT}/wp-content/themes/twenty*
else
	echo >&2 "Wordpress seems to be installed."
fi

envs=(
	MYSQL_ROOT_PASSWORD
	MYSQL_DATABASE
	SQL_DUMP_DATA
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

exec "$@"