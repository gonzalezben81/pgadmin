### Get the official Ubuntu 22.04 image from Dockerhub
FROM ubuntu:22.04

# Define PHP version as a variable
ENV PHP_VERSION=7.4

# Set PostgreSQL username and password as environment variables
ENV POSTGRES_USER=myuser
ENV POSTGRES_PASSWORD=mypassword
ENV POSTGRES_DB=mydb

# Install necessary packages
RUN apt-get update -y && \
    apt-get install -y unzip wget software-properties-common nginx && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update -y && \
    apt-get install -y php${PHP_VERSION}-fpm php${PHP_VERSION}-pgsql php${PHP_VERSION}-mbstring && \
    apt-get install -y postgresql postgresql-contrib

# Configure PHP
RUN sed -i 's/^cgi\.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/${PHP_VERSION}/fpm/php.ini

# Nginx configuration
RUN tee /etc/nginx/sites-available/default > /dev/null <<EOL
server {
        listen 80;

        root /var/www/phppgadmin;

        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                try_files \$uri \$uri/ =404;
        }

        location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}
EOL

# Download and unzip the phpPgAdmin archive
RUN wget https://github.com/phppgadmin/phppgadmin/archive/refs/heads/master.zip -O /var/www/phppgadmin.zip && \
    unzip /var/www/phppgadmin.zip -d /var/www/ && \
    mv /var/www/phppgadmin-master /var/www/phppgadmin && \
    rm /var/www/phppgadmin.zip

# Configure phpPgAdmin
RUN mv /var/www/phppgadmin/conf/config.inc.php-dist /var/www/phppgadmin/conf/config.inc.php && \
    sed -i "s/\$conf\['servers'\]\[0\]\['host'\] = '';/\$conf['servers'][0]['host'] = 'localhost';/g" /var/www/phppgadmin/conf/config.inc.php && \
    sed -i "s/\$conf\['extra_login_security'\] = true;/\$conf['extra_login_security'] = false;/g" /var/www/phppgadmin/conf/config.inc.php

# Get PostgreSQL version and set it as an environment variable
RUN export PSQL_VERSION=$(psql --version | awk '{print $3}') && \
    echo "PostgreSQL version is: $PSQL_VERSION" && \
    echo "export PSQL_VERSION=$PSQL_VERSION" >> /etc/environment

# Update pg_hba.conf to allow password authentication
RUN PG_HBA_PATH=$(find /etc/postgresql/ -name pg_hba.conf) && \
    echo "# TYPE  DATABASE        USER            ADDRESS                 METHOD" >> "$PG_HBA_PATH" && \
    echo "host    all             all             0.0.0.0/0               md5" >> "$PG_HBA_PATH" && \
    echo "host    all             all             ::/0                    md5" >> "$PG_HBA_PATH"

# Modify pg_hba.conf to change local authentication method
RUN PG_HBA_PATH=$(find /etc/postgresql/ -name pg_hba.conf) && \
    sed -i "s/local   all             all                                     peer/local   all             all                                     md5/" "$PG_HBA_PATH"

# Switch to the postgres user and create the PostgreSQL user and database
USER postgres
RUN service postgresql start && \
    psql -U postgres -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';" && \
    psql -U postgres -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"

# Switch back to root user
USER root

# Test Nginx configuration
RUN nginx -t

EXPOSE 8080

# Set the working directory
WORKDIR /var/www/phppgadmin

# Start PHP-FPM and NGINX when the container starts
CMD ["sh", "-c", "service php${PHP_VERSION}-fpm start && nginx -g 'daemon off;'"]
### Get the official Ubuntu 22.04 image from Dockerhub
FROM ubuntu:22.04

# Define PHP version as a variable
ENV PHP_VERSION=7.4

# Set PostgreSQL username and password as environment variables
ENV POSTGRES_USER=myuser
ENV POSTGRES_PASSWORD=mypassword
ENV POSTGRES_DB=mydb

# Install necessary packages
RUN apt-get update -y && \
    apt-get install -y unzip wget software-properties-common nginx && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update -y && \
    apt-get install -y php${PHP_VERSION}-fpm php${PHP_VERSION}-pgsql php${PHP_VERSION}-mbstring && \
    apt-get install -y postgresql postgresql-contrib

# Configure PHP
RUN sed -i 's/^cgi\.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/${PHP_VERSION}/fpm/php.ini

# Nginx configuration
RUN tee /etc/nginx/sites-available/default > /dev/null <<EOL
server {
        listen 80;

        root /var/www/phppgadmin;

        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                try_files \$uri \$uri/ =404;
        }

        location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}
EOL

# Download and unzip the phpPgAdmin archive
RUN wget https://github.com/phppgadmin/phppgadmin/archive/refs/heads/master.zip -O /var/www/phppgadmin.zip && \
    unzip /var/www/phppgadmin.zip -d /var/www/ && \
    mv /var/www/phppgadmin-master /var/www/phppgadmin && \
    rm /var/www/phppgadmin.zip

# Configure phpPgAdmin
RUN mv /var/www/phppgadmin/conf/config.inc.php-dist /var/www/phppgadmin/conf/config.inc.php && \
    sed -i "s/\$conf\['servers'\]\[0\]\['host'\] = '';/\$conf['servers'][0]['host'] = 'localhost';/g" /var/www/phppgadmin/conf/config.inc.php && \
    sed -i "s/\$conf\['extra_login_security'\] = true;/\$conf['extra_login_security'] = false;/g" /var/www/phppgadmin/conf/config.inc.php

# Get PostgreSQL version and set it as an environment variable
RUN export PSQL_VERSION=$(psql --version | awk '{print $3}') && \
    echo "PostgreSQL version is: $PSQL_VERSION" && \
    echo "export PSQL_VERSION=$PSQL_VERSION" >> /etc/environment

# Update pg_hba.conf to allow password authentication
RUN PG_HBA_PATH=$(find /etc/postgresql/ -name pg_hba.conf) && \
    echo "# TYPE  DATABASE        USER            ADDRESS                 METHOD" >> "$PG_HBA_PATH" && \
    echo "host    all             all             0.0.0.0/0               md5" >> "$PG_HBA_PATH" && \
    echo "host    all             all             ::/0                    md5" >> "$PG_HBA_PATH"

# Modify pg_hba.conf to change local authentication method
RUN PG_HBA_PATH=$(find /etc/postgresql/ -name pg_hba.conf) && \
    sed -i "s/local   all             all                                     peer/local   all             all                                     md5/" "$PG_HBA_PATH"

RUN sed -i "\$a# TYPE  DATABASE        USER            ADDRESS                 METHOD\nhost    all             all             0.0.0.0/0               md5" $(find /etc/postgresql -name pg_hba.conf | head -n 1) && \
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $(find /etc/postgresql -name postgresql.conf | head -n 1) && \
    service postgresql restart && \
    service postgresql start

# Switch to the postgres user and create the PostgreSQL user and database
USER postgres
RUN service postgresql start && \
    psql -U postgres -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';" && \
    psql -U postgres -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"

# Switch back to root user
USER root

# Test Nginx configuration
RUN nginx -t

EXPOSE 8080

# Set the working directory
WORKDIR /var/www/phppgadmin

# Start PHP-FPM and NGINX when the container starts
CMD ["sh", "-c", "service php${PHP_VERSION}-fpm start && nginx -g 'daemon off;'"]
