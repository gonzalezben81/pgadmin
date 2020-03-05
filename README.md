---
title: "How to Install PostgreSQL NGINX and PHPPGADMIN on Ubuntu 18.04"
author: "Ben Gonzalez"
date: "3/4/2020"
output: html_document
---




Let's start by updating our server and installing NGINX.

````bash
sudo apt-get update

sudo apt-get install nginx
````

Now let's install PHP for NGINX

```console
sudo apt-get isntall php-fpm
```


Let's edit our configuration file for php

```console
sudo nano /etc/php/7.2/fpm/php.ini
```

Search for the following using **ctrl+W** and change the setting from 1 to 0.

```console
cgi.fix_pathinfo=0
```

Restart our php configuration
```console
sudo systemctl restart php7.2-fpm
```

We need to edit our NGINX configuration to allow us to utilize the PHP code we will be using.

```console
sudo nano /etc/nginx/sites-available/default
```


Now let's edit our default configuration to look like the following. 

```console
server {
        listen 80;
        
        root /var/www/html;
        
        index index.php index.html index.htm index.nginx-debian.html;
        
        server_name _;

        location / {
                try_files $uri $uri/ =404;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}

```

Now we need to test our configuration and reload Nginx.

```console
sudo nginx -t

sudo systemctl reload nginx
```

Now let's create a PHP file to test our configuration. 
```console
sudo nano /var/www/html/info.php
```


Enter the following into the file. 

```console
<?php
phpinfo();

?>
```

Now go to your site at http://your-ip-address/info.php

You should see a web page similar to this one. 

![](www/php_info_1804.png)

If all looks like the image above you may continue. 

Next we want to download phppgadmin and unzip the file and make sure to change to the /var/www directory to download and unzip the file. 

```console

cd /var/wwww

wget https://github.com/phppgadmin/phppgadmin/archive/REL_5-6-0.tar.gz

###Unzip the file

tar -xvzf REL_5-6-0.tar.gz

###Move the file and rename it

mv phppgadmin-REL_5-6-0 phppgadmin

###Check that everything is in the file we need
cd phppgadmin

ls -a
```

Restart Nginx again

```console
###Check our Nginx file is correct
sudo nginx -t

###Restart Nginx
sudo service nginx restart
```

Now we need to move and rename a file in our phppgadmin folder

```console
###Enter the conf folder
cd /conf
###Check the contents
ls -a
###Move and rename the config.inc.php-dist file to config.inc.php
mv config.inc.php-dist config.inc.php
```

Now you will want to edit the file **config.inc.php**

```console
sudo nano config.inc.php
```


Change the **$conf['servers'][0]['host'] = '';** to the configuration below.

```console
// Hostname or IP address for server.  Use '' for UNIX domain socket.
        // use 'localhost' for TCP/IP connection on this computer
        $conf['servers'][0]['host'] = 'localhost';
```

Change the **$conf['extra_login_security'] = true;** to the configuration below.

```console
       // If extra login security is true, then logins via phpPgAdmin with no
        // password or certain usernames (pgsql, postgres, root, administrator)
        // will be denied. Only set this false once you have read the FAQ and
        // understand how to change PostgreSQL's pg_hba.conf to enable
        // passworded local connections.
        $conf['extra_login_security'] = false;

```
Now you want to isntall php-pgsql

```console
sudo apt-get install php-pgsql
```

Next:

```console
sudo apt-get install postgresql postgresql-contrib
```   

Switch to the postgres user but first add it as a super user. 

```console
root@ubuntu:~# gpasswd -a postgres sudo
Adding user postgres to group sudo
```

You can also add a password for the postgres user as well

```console
root@ubuntu:~# passwd postgres
Enter new UNIX password:
Retype new UNIX password:
passwd: password updated successfully
root@ubuntu:~#

```


Next you will want to edit the **/etc/nginx/sites-available/default** file again to the configuration below. This will point our files to the phppgadmin files we need to enable the GUI interface.
   
```console
sudo nano /etc/nginx/sites-available/default
```
   
   
```console
server {
        listen 80;
        
        #root /var/www/html;
        root /var/www/phppgadmin;
         
        index index.php index.html index.htm index.nginx-debian.html;
        server_name _;

        location / {
                try_files $uri $uri/ =404;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}

```  

Restart the Nginx server again. 

```console
###Test our configuration
sudo nginx -t

###Restat nginx
sudo service nginx restart

```

You should see the following output at **http://your-ip-address**

---

![](www/postgresql_front_page.png)


----

### Add the postgrest API to the database

Switch to the postgres user

```console
su - postgres
```

Next we want to download the postgrest package. 

You can get the latest download from here:

https://github.com/PostgREST/postgrest/releases/tag/v6.0.2


```console
wget https://github.com/PostgREST/postgrest/releases/download/v6.0.2/postgrest-v6.0.2-ubuntu.tar.xz
```

Unzip the download


```console
# download from https://github.com/PostgREST/postgrest/releases/latest

# tar xfJ postgrest-<version>-<platform>.tar.xz

tar xfJ postgrest-v6.0.2-ubuntu.tar.xz 
```


Now run the follwing command and you should get some output with a version. 

```console
./postgrest
```

You should get the following output. 


```console
Usage: postgrest FILENAME
  PostgREST 6.0.2 (713b214) / create a REST API to an existing Postgres database

Available options:
  -h,--help                Show this help text
  FILENAME                 Path to configuration file

```

Now switch to psql to create a schema and put some data into a table. 

```console
postgres@ubuntu$ psql
psql (10.12 (Ubuntu 10.12-0ubuntu0.18.04.1))
Type "help" for help.

postgres=#

```

The following sequences are borrowed from the tutorial at: https://postgrest.org/en/v6.0/tutorials/tut0.html

```sql
create schema api;
```

The API will have one endpoint called todos



```sql
create table api.todos (
  id serial primary key,
  done boolean not null default false,
  task text not null,
  due timestamptz
);

insert into api.todos (task) values
  ('finish tutorial 0'), ('pat self on back');
```


Next make a role to use for anonymous web requests. When a request comes in, PostgREST will switch into this role in the database to run queries.


```sql
create role web_anon nologin;

grant usage on schema api to web_anon;
grant select on api.todos to web_anon;
```

The web_anon role has permission to access things in the api schema, and to read rows in the todos table.


It’s a good practice to create a dedicated role for connecting to the database, instead of using the highly privileged postgres role. So we’ll do that, name the role authenticator and also grant him the ability to switch to the web_anon role :



```sql
create role authenticator noinherit login password 'mysecretpassword';
grant web_anon to authenticator;
```


And exit/quit postgresql

```sql
\q
```

Now we want to create the **conf** file that will run **postgrest** for us.

PostgREST uses a configuration file to tell it how to connect to the database. Create a file tutorial.conf with this inside:

Create and open the file for editing.
```console
sudo nano tutorial.conf
```

Place the following in the config file. 

```console
db-uri = "postgres://authenticator:mysecretpassword@localhost:5433/postgres"
db-schema = "api"
db-anon-role = "web_anon"
```


The configuration file has other options, but this is all we need. Now run the server:


Run the following command and open a new window for your session as well. 
```console
./postgrest tutorial.conf
```

In the duplicate window run the following. 

```console
curl http://localhost:3000/todos
```

You should see the following results in the duplicate session window. 

```console
[
  {
    "id": 1,
    "done": false,
    "task": "finish tutorial 0",
    "due": null
  },
  {
    "id": 2,
    "done": false,
    "task": "pat self on back",
    "due": null
  }
]
```


Now we want to start the postgrest conf file on boot. 

We can create an **.sh** file and utilize an **rc.local** file to start postgrest at boot. 

```console
sudo nano start_postgres.sh
```

Copy the following contents into the file. We are basically creating a bash file to run our tutorial.conf file that we have already created. 

```console

./postgrest tutorial.conf

```

Check to see that our **.sh** file runs. 

```console
./start_postgres.sh
```

You should receive the following output. 


```console
Attempting to connect to the database...
Listening on port 3000
Connection successful

```

Modify the file to allow it to run. 

```console
sudo chmod +x start_postgres.sh
```

Exit the postgres user and become root.

```console
exit
```

Create our **rc.local** file and place the below configuration into it. You will want to point your **bash** to whatever directory you have placed your **start_postgres.sh** file in. 

```console
sudo nano rc.local
```

Contents of **rc.local**

```console
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

su - postgres -c 'bash start_postgres.sh'

exit 0


```

Test to see that our file works. 

```console
sudo /etc/rc.local start
```

You should see the same output you saw earlier. 

```console
Attempting to connect to the database...
Listening on port 3000
Connection successful
```

Lastly we need to configure out Nginx file one last time allow us to hit the API at port 3000.


```console
sudo nano /etc/nginx/sites-available/default

```

```console
  # upstream configuration
  upstream postgrest {
    server localhost:3000;
  }
  
      # expose to the outside world
    location /api/ {
      default_type  application/json;
      proxy_hide_header Content-Location;
      add_header Content-Location  /api/$upstream_http_content_location;
      proxy_set_header  Connection "";
      proxy_http_version 1.1;
      proxy_pass http://postgrest/;
    }
```

The complete file should now look like the one below. 

```console
##
# You should look at the following URL's in order to grasp a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# https://www.nginx.com/resources/wiki/start/
# https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/
# https://wiki.debian.org/Nginx/DirectoryStructure
#
# In most cases, administrators will remove this file from sites-enabled/ and
# leave it as reference inside of sites-available where it will continue to be
# updated by the nginx packaging team.
#
# This file will automatically load configuration files provided by other
# applications, such as Drupal or Wordpress. These applications will be made
# available underneath a path with that package name, such as /drupal8.
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##

# Default server configuration
#


  # ...
  # upstream configuration
  upstream postgrest {
    server localhost:3000;
  }


server {
	listen 80 default_server;
	listen [::]:80 default_server;

	# SSL configuration
	#
	# listen 443 ssl default_server;
	# listen [::]:443 ssl default_server;
	#
	# Note: You should disable gzip for SSL traffic.
	# See: https://bugs.debian.org/773332
	#
	# Read up on ssl_ciphers to ensure a secure configuration.
	# See: https://bugs.debian.org/765782
	#
	# Self signed certs generated by the ssl-cert package
	# Don't use them in a production server!
	#
	# include snippets/snakeoil.conf;

#	root /var/www/html;
	root /var/www/phppgadmin;
	# Add index.php to the list if you are using PHP
	index index.php index.html index.htm index.nginx-debian.html;

	server_name _;
	
	location /api/ {
             default_type  application/json;
             proxy_hide_header Content-Location;
             add_header Content-Location  /api/$upstream_http_content_location;
             proxy_set_header  Connection "";
             proxy_http_version 1.1;
             proxy_pass http://postgrest/;
            # proxy_pass http://localhost:3000;
          }

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		try_files $uri $uri/ =404;
	}

	# pass PHP scripts to FastCGI server
	#
	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
	#
	#	# With php-fpm (or other unix sockets):
		fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
	#	# With php-cgi (or other tcp sockets):
	#	fastcgi_pass 127.0.0.1:9000;
	}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	location ~ /\.ht {

		deny all;
	}
}
```

Check to make sure our configuration file is correct.

```console
sudo nginx -t
```

Now reboot the system and utilize your ip address to check to see if everything works. This is required to start **postgrest** at boot. 


```console
sudo reboot
```

You should get the following output at your ipaddress. http://your.ipaddress/api/todos

![](www/api_todos.png)


