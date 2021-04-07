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
define( 'WP_ENVIRONMENT_TYPE', 'local' );
define( 'MWFORM_DEBUG', true );
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
        wp option update image_default_size 'full' --allow-root
        wp option update thumbnail_crop '0' --allow-root
        wp option update permalink_structure '/%postname%/' --allow-root

        #Truncate tables
        echo >&2 "Initializing tables..."
        wp db query "TRUNCATE table ${WP_DB_PREFIX}posts;" --allow-root
        wp db query "TRUNCATE table ${WP_DB_PREFIX}postmeta;" --allow-root
        wp db query "TRUNCATE table ${WP_DB_PREFIX}links;" --allow-root
        wp db query "TRUNCATE table ${WP_DB_PREFIX}comments;" --allow-root
        wp db query "TRUNCATE table ${WP_DB_PREFIX}commentmeta;" --allow-root
        wp db query "TRUNCATE table ${WP_DB_PREFIX}terms;" --allow-root
        wp db query "TRUNCATE table ${WP_DB_PREFIX}termmeta;" --allow-root
        wp db query "TRUNCATE table ${WP_DB_PREFIX}term_taxonomy;" --allow-root
        wp db query "TRUNCATE table ${WP_DB_PREFIX}term_relationships;" --allow-root

        # Install extra plugins specified by $WP_INSTALL_PLUGINS
        if [[ -z "${WP_INSTALL_PLUGINS}" ]]; then
            echo >&2 "env var \$WP_INSTALL_PLUGINS is empty - skipping installing extra plugins";
        else
            echo >&2 "Downloading extra plugins"
            for TEMP_WP_PLUGIN in $WP_INSTALL_PLUGINS; do
                echo >&2 "Installing extra plugin ${TEMP_WP_PLUGIN}..."
                if ! $(wp plugin is-installed ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root); then
                    wp plugin install ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root
                fi
            done

            unset "TEMP_WP_PLUGIN"
        fi

        # Activate extra plugins specified by $WP_ACTIVATE_PLUGINS
        if [[ -z "${WP_ACTIVATE_PLUGINS}" ]]; then
            echo >&2 "env var \$WP_ACTIVATE_PLUGINS is empty - skipping activating extra plugins";
        else
            for TEMP_WP_PLUGIN in $WP_ACTIVATE_PLUGINS; do
                echo >&2 "Activating extra plugin ${TEMP_WP_PLUGIN}..."
                if $(wp plugin is-installed ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root); then
                    wp plugin activate ${TEMP_WP_PLUGIN} --path=${WP_ROOT} --allow-root
                fi
            done

            unset "TEMP_WP_PLUGIN"
        fi

        # Setup plugin options
        echo >&2 "Setup plugin options..."
        if $(wp plugin is-installed wordpress-seo --path=${WP_ROOT} --allow-root); then
            echo "Update yoast options";
            YOAST_OPTION=$(wp option get wpseo --format=json --allow-root | \
            sed -n '$p' | \
            sed 's/"keyword_analysis_active":true/"keyword_analysis_active":false/' | \
            sed 's/"content_analysis_active":true/"content_analysis_active":false/' | \
            sed 's/"enable_cornerstone_content":true/"enable_cornerstone_content":false/' | \
            sed 's/"enable_text_link_counter":true/"enable_text_link_counter":false/' | \
            sed 's/"enable_xml_sitemap":true/"enable_xml_sitemap":false/' | \
            sed 's/"onpage_indexability":true/"onpage_indexability":false/' | \
            sed 's/"enable_admin_bar_menu":true/"enable_admin_bar_menu":false/' | \
            sed 's/"show_onboarding_notice":true/"show_onboarding_notice":false/' | \
            sed 's/"enable_text_link_counter":true/"enable_text_link_counter":false/') && \
            wp option update wpseo $YOAST_OPTION --format=json --allow-root
        fi

        #Activate theme"
        if [ -n "${WP_THEME_NAME}" ]; then
            echo >&2 "Activating Theme..."
            wp theme activate ${WP_THEME_NAME} --allow-root
        fi

        #Dump
        echo >&2 "Dumping SQL Data..."
        mysqldump -uroot --password="${MYSQL_PASSWORD}" -B ${MYSQL_DATABASE} -hmysql | gzip -9vf > ${SQL_DUMP_DATA}

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
    if [ -d ${WP_ROOT}/wp-content/plugins/akismet ]; then
        echo >&2 "Remove Akismet"
        wp plugin delete akismet --allow-root
    fi
    if [ -e ${WP_ROOT}/wp-content/plugins/hello.php ]; then
        echo >&2 "Remove Hello Dolly"
        wp plugin delete hello --allow-root
    fi

    # Delete Default theme
    ls ${WP_ROOT}/wp-content/themes/twenty* >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo >&2 "Remove Default Themes"
        rm -Rf ${WP_ROOT}/wp-content/themes/twenty*
    fi

    if [ ! -e ${WP_ROOT}/.htaccess ]; then
	{ \
		echo '# BEGIN Upload file limit'; \
		echo ''; \
		echo 'php_value upload_max_filesize 512M'; \
		echo 'php_value post_max_size 512M'; \
		echo 'php_value memory_limit 512M'; \
		echo 'php_value max_execution_time 600'; \
		echo 'php_value max_input_time 600'; \
		echo ''; \
		echo '# END Upload file limit'; \
		echo ''; \
		echo ''; \
		echo '# BEGIN WordPress'; \
		echo ''; \
		echo 'RewriteEngine On'; \
		echo 'RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'; \
		echo 'RewriteBase /'; \
		echo 'RewriteRule ^index\.php$ - [L]'; \
		echo 'RewriteCond %{REQUEST_FILENAME} !-f'; \
		echo 'RewriteCond %{REQUEST_FILENAME} !-d'; \
		echo 'RewriteRule . /index.php [L]'; \
		echo ''; \
		echo '# END WordPress'; \
	} > ${WP_ROOT}/.htaccess;
    fi

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
	WP_ACTIVATE_PLUGINS
)

# now that we're definitely done writing configuration, let's clear out the relevant envrionment variables (so that stray "phpinfo()" calls don't leak secrets from our code)
for e in "${envs[@]}"; do
	unset "$e"
done

exec "$@"