---
title: "How to Install PostgreSQL NGINX and PHPPGADMIN on Ubuntu 18.04"
author: "Ben Gonzalez"
date: "3/4/2020"
output: html_document
---




Let's start by updating our server and installing NGINX.

````console
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
```

```



Now lets add an info.php file to ensure that php is properly working on nginx. 
```console
sudo nano /etc/nginx/sites-available/default
```


Now let's edit our default configuration to look like the following. 

```console
server {
        listen 80;
        root /var/www/html;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name example.com;

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
        server_name example.com;

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


![](www/postgresql_front_page.png)