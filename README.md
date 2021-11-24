### This is a complete step-by-step tutorial to validate ft_server project (s42 network)
### The goal of the project is to learn to use Docker, phpMyAdmin, Wordpress and mySQL
### Update: in may 2021 ft_server project was removed from the main core.
### If you are interested in the project, you can find its subject [here](./srcs/images/ft_server_subject.pdf)

--------------------------------------------------------------------------------------------------------------------------------------
# Prerequisites:
### - 📚 You know all the concepts needed for this project: containers, images, ports etc.
### - 🐳 You have Docker installed and it is running ([**download link**](https://www.docker.com/get-started))

--------------------------------------------------------------------------------------------------------------------------------------
# Building, running and cleaning up your containers:
You will often need to test your work. The following commands are used *A LOT* and I recommend to create a Makefile with rules that will execute them for you to make your life easier ([example](./Makefile))

`docker build -t ft_server .` will **_🛠️ build_** our Docker container and name it "ft_server". 

`docker run -it --rm -p 80:80 -p 443:443 ft_server` After it's built this command will  **_🏃‍♂️ run_** our container and:
  * `-it` open its terminal and allow us to execute commands inside (useful to manually check the contents of the container)
  * `--rm` automatically remove the container once it's stopped
  * `-p` link the necessary ports between the container and our computer (80 and 443)
  * And finally, name it "ft_server"
  * Note: while on MacOS specifying the ports like this is enough, on other OS you might need to add EXPOSE 80 and EXPOSE 443 in your Dockerfile to make it work
 
`docker rmi $(docker images -q)` will remove all the images

`docker rm $(docker ps -qa)` will remove all the containers

`docker system prune` will cleanup the temporary files and the rest of remaining used space

--------------------------------------------------------------------------------------------------------------------------------------
# Project parts summary:
#### 1) [Create a Dockerfile and download a Debian Buster image](#create-a-dockerfile-and-download-a-debian-buster-image)
#### 2) [Install all of the dependencies](#install-all-of-the-dependencies)
#### 3) [Install and configure NGINX](#install-and-configure-nginx)
#### 4) [Add SSL protocol and autoindex](#add-ssl-protocol-and-autoindex)
#### 5) [Install and configure phpMyAdmin](#install-and-configure-phpmyadmin)
#### 6) [Install and configure Wordpress](#install-and-configure-wordpress)
#### 7) [The end](#the-end)

--------------------------------------------------------------------------------------------------------------------------------------
# Create a Dockerfile and download a Debian Buster image
All you need to do is:
* Create a file named Dockerfile
* Add a line `FROM debian:buster` inside.
* Add lines `RUN apt-get update` and `RUN apt-get upgrade -y`
<br />

Dockerfile is like a Makefile, but instead of executing commands in your terminal it will do it inside Docker images.

The command `FROM` tells Docker to download the image that follows and use the commands we'll add in the next step inside this image.

Here we are using an empty Debian Buster operating system image as asked in the subject.

You can imagine that we download an empty Windows or MacOS now and in the next step we will start installing the dependencies needed for the rest of our project.

Before we do that, we need to update the Debian Buster packages to make sure everything is up to date just as we need.

This is simply done by adding `RUN apt-get update` and `RUN apt-get upgrade -y` to our Dockerfile. 

`RUN` is used in Dockerfile to execute the command inside the image during the container build phase, as if it is entered in the terminal of our Debian OS.

It is mostly used to install dependencies and set up the configuration files.

For any commands that need to be ran during the container run phase (to start services like NGINX),
we will use the command `CMD` instead which will be explained later on.

<br />

```Dockerfile
#------------------ 1. Create a Dockerfile and download Debian Buster image ----------------------
# Download debian:buster from Docker and use it as main image here
FROM debian:buster

# Update Debian Buster packages
RUN apt-get update
RUN apt-get upgrade -y
#-------------------------------------------------------------------------------------------------
```
Now if we try to build our docker image and run it, Debian Buster image will be downloaded from Docker and it will be updated.


--------------------------------------------------------------------------------------------------------------------------------------
# Install all of the dependencies
Now that we have our Dockerfile and an empty Debian OS with basic packages, we will install the dependencies and tools needed for further steps in the project.

This is done by adding several `apt-get install` to our Dockerfile.

For this project there is a couple of things we need:

```Dockerfile
#----------------------------------- 2. Intall Dependencies --------------------------------------
# Sysvinit-utils for "service" command used to easily start and restart our nginx/php/mysql
RUN apt-get install sysvinit-utils

# Wget is used to easily download phpMyAdmin / Wordpress
RUN apt-get -y install wget

# Nginx is an open source web server tool we are going to use to connect our Docker container image to our webpage
RUN apt-get -y install nginx

# MariaDB is a tool used to manage databases. It's a community "fork" of MySQL (= improved version of MySQL)
RUN apt-get -y install mariadb-server

# Php packages are needed to read our configuration files and properly connect all of our components together
# In case a php package is missing, we will get an error when launching php related services later
RUN apt-get -y install php-cgi php-common php-fpm php-pear php-mbstring
RUN apt-get -y install php-zip php-net-socket php-gd php-xml-util php-gettext php-mysql php-bcmath
#-------------------------------------------------------------------------------------------------
```
Now if we try to build our docker image and run it, it downloads/updates Debian Buster and downloads all the dependencies we need.


--------------------------------------------------------------------------------------------------------------------------------------

# Install and configure NGINX
In the previous part of the project we have downloaded nginx using `RUN apt-get -y install nginx`.

Now, we will configure it to connect our container to our webpage.

In order to do so, NGINX will need a configuration file where we will tell it what is our webpage name, what ports he needs to "listen" to and what other tools we will use.

Normally on our computer we would simply create a file and write inside, but since we need to do it inside the container, we prepare the configuration file in advance and then copy it inside our container when we need it.

In our project folder, let's create a "srcs" folder as required by subject and create an empty file named "localhost" inside.

localhost is the webpage we will be using to acces our web server in this project.

Add the following lines to our "[**localhost**](./srcs/localhost)" file:
```php
server {
     # tells to listen to port 80 (http port)
     listen 80;
     # same but for IPV6
     listen [::]:80;
     # tells the name(s) of our website
     server_name localhost www.localhost;
     # will redirect us to https://$host$request_uri;
     # when we try to reach the website name in our browser
     return 301 https://$host$request_uri;
 }
 ```
 We just told NGINX to listen to http port 80, told it the name of our website and setup a redirection to it.
 
 Now that our configuration is ready, we will need to add some lines to our Dockerfile to copy it inside the container and set it up:
 ```Dockerfile
#---------------------------------- 3. Install and configure Nginx  ------------------------------
# NGINX will need a folder where it will search for everything related to our website
# We can use the "html" folder that already exists in var/www directory,
# but it's a good practice to have a separate folder for every website in case we create more than 1
RUN mkdir /var/www/localhost

# COPY copies files from the given directory on our computer to given directory inside our container.
# If a file already exists in the specified directory, it will overwrite it
# We place it inside /etc/nginx/sites-available as required per NGINX documentation
COPY srcs/localhost /etc/nginx/sites-available

# We also need to create a link between the 2 following folder to "enable" our website
RUN ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled

# For the next steps, we will be working inside /var/www/localhost directory
# To avoid writing /var/www/localhost before every command, we can change current working directory
# WORKDIR command in dockerfile changes the directory where next commands will be executed
WORKDIR /var/www/localhost/
#-------------------------------------------------------------------------------------------------
```
Now if we try to build our docker image and run it, it downloads/updates Debian Buster, all of the dependencies we need
and also copies our NGINX configuration file named "[**localhost**](./srcs/localhost)" inside the container.

However, we still cannot reach the localhost or local ip address websites. Why is that?

The answer is simple: NGINX is intalled but it is not running, so it is not doing anything yet!

Let's activate it!

When we build the container and run it in terminal mode, we will be able to see the container's prompt.

To activate NGINX, we can simply execute "nginx" or "service nginx start" inside this prompt.

Later, I will explain a more elegant solution to automatically start NGINX and other services while running our container.

After one of these commands is executed, if you try to reach [0.0.0.0](http://0.0.0.0) or [127.0.0.1](http://127.0.0.1) in your browser while the container is running you will now get "Welcome to nginx!" webpage, which confirms that NGINX is configured properly 🙌

![](srcs/images/welcome_nginx.png)

--------------------------------------------------------------------------------------------------------------------------------------

# Add SSL protocol and autoindex
Previously we have added a "[localhost](./srcs/localhost)" file in our "srcs" folder which was telling NGINX to listen to http port.

In this step, we will setup SSL protocol to secure the connection to our website and add an autoindex which will display
the contents of our website as a directory on our homepage.

#### SSL Protocol

First we will need to generate the SSL certificate and key.

This can be done by using `openssl` command [(explanation here)](https://linuxize.com/post/creating-a-self-signed-ssl-certificate/)

So let's add the necessary command in our [Dockerfile](./Dockerfile):

```Dockerfile
#------------------------------ 4. Add SSL protocol and autoindex --------------------------------
# SSL creates a secured channel between the web browser and the web server
#
# "openssl" command allows us to create a certificate and key ourselves
# here below is the explanation of the flags used:
# -x509 specifies a self signed certificate
# -nodes specifies that the private key wont be encrypted
# -days specifies the validity (in days) of the certificate
# -subj allows us to use the following string (and not create a separate file for it)
# The next line is personnal information, you will need to use your own
# -newkey creates a new certificate request and a new private key 
# -rsa 2018 is the standard key size (in bits)
# -keyout specifies where to save the key
# -out specifies the file name
RUN openssl req -x509 -nodes -days 30 -subj "/C=BE/ST=Belgium/L=Brussels/O=42 Network/OU=s19/CN=ysoroko" -newkey rsa:2048 -keyout /etc/ssl/nginx-selfsigned.key -out /etc/ssl/nginx-selfsigned.crt;
#-------------------------------------------------------------------------------------------------
```

Now that we have our SSL certificate and key, let's configure the SSL protocol in our "localhost" NGINX configuration file.

While we are here, we will also add the autoindex section which will allow us to see the contents of our "var/www/localhost" directory
when reaching our website.

We will add the following lines at the end (after the first "server" section):

```php
server {
    # tells to listen to port 443
    listen 443 ssl;
    # same but for IPV6
    listen [::]:443 ssl;
    # tells the name(s) of our website
    server_name localhost www.localhost;

    # Enables SSL protocol
    ssl on;
    # Tells where to look for SSL certificate (needs to be the same as in our openssl command before)
    ssl_certificate /etc/ssl/nginx-selfsigned.crt;
    # Tells where to look for SSL key (needs to be the same as in our openssl command before)
    ssl_certificate_key /etc/ssl/nginx-selfsigned.key;

    # Tells where to look for all the files related to our website
    root /var/www/localhost;
    # Enables autoindex to see the contents of the previous line's directory when we reach our website
    autoindex on;
    # Tells the possible names of the index file
    index index.html index.htm index.nginx-debian.html index.php;
    # Tells to check for existence of files before moving on
	location / {
		try_files $uri $uri/ =404;
	}
    # Specifies the php configuration
	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/run/php/php7.3-fpm.sock;
	}
 }
 ```
Our "localhost" file should now look like [this](./srcs/localhost).

We have now succesfully added SSL protocol to our website and added an autoindex!

You can try to build and run your container in terminal mode, then start up NGINX just as before (by running "nginx" or "service nginx start").

At this point of our project, if you try to reach [localhost webpage](https://localhost/), you will see a message of the kind:

![](srcs/images/your_connection_is_not_private.png)

You can then simply click on "Advanced" button and then click on "Proceed to localhost (unsafe)" to reach the index homepage of our project.

The contents of our /var/www/localhost are empty so you will see the following:

![](srcs/images/empty_index.png)

#### Autoindex

As stated before, this "index of /" homepage is displayed because Autoindex is activated.

To deactivate it, you can replace "on" by "off" in "localhost" file, then rebuild and rerun the container (don't forget to start up nginx).

This will deactivate our "index of /" homepage and result in a "403 Forbidden" error while opening [localhost](https://localhost) webpage.

![](srcs/images/403_forbidden.png)

Since we created an auto-signed ssl certificate and key we get the warning "Your connection is not private".

However, the ssl protocol is up and running.

You can see that the website is using our certificate and key by clicking "Not Secure" -> Certificate (on Google Chrome) to see all the details we entered before in openssl command.

Since we are not a verified party who can issue SSL certificates, we are unfortunately not trustworthy 😢.

Another sign that we are using ssl is that we are using "https://" and not "http://" to reach the webpage.

#### Conclusion

In this step we have added the SSL protocol and the autoindex. Our website is now reachable via [localhost](https://localhost/) webpage,
it uses a secure connection and it displays the contents of the container's /var/www/localhost directory when the autoindex is turned on in our localhost
NGINX configuration file (or 403_forbidden error when the autoindex is turned off).

--------------------------------------------------------------------------------------------------------------------------------------

# Install and configure phpMyAdmin
In step 2 we have installed mariadb-server by using `RUN apt-get -y install mariadb-server`.

Now we will create a sample database, download and configure phpMyAdmin and make sure it works by detecting our database.

[**Here (at step 2)**](https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mariadb-php-lemp-stack-on-debian-10) you can see how to create and setup a mariadb database by running several commands inside Debian Buster terminal. 

For our project we need to tell our container to execute these commands automatically, without typing them ourselves.

This can be achieved by creating a ".sh" file with some "echo" commands and pipes that we will execute when running our container. 

Also in previous steps we had to manually type "nginx" or "service nginx start" in the container's terminal to start up NGINX.

No more 😎!

This command will now be placed in ".sh" file and executed with all the other commands we need.

In our "srcs" folder, let's create a "[start.sh](./srcs/start.sh)" file.

We will need to:
1) Start all the required services 
2) Create a database we can later use for Wordpress to check that our phpMyAdmin detects it
3) Make sure that the database has correct access rights so that we can freely use it
4) Restart some services to apply the changes

To do so, let's add the following lines to our "[start.sh](./srcs/start.sh)" file:

```Shell
# Start up NGINX
service nginx start;

# Start up MySQL
service mysql start;

# Start up PHP
service php7.3-fpm start;

#------------------------ Create & configure Wordpress database ----------------------------------------

# 1. Connect to MySQL using "root" account and create a database named "wordpress"
echo "CREATE DATABASE wordpress;" | mysql -u root --skip-password;

# 2. Gives the user "root" all possible rights related to "wordpress" database
echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'localhost' WITH GRANT OPTION;" | mysql -u root --skip-password;

# 3. Apply the previous changes (otherwise it waits until we restart the server)
echo "FLUSH PRIVILEGES;" | mysql -u root --skip-password;

# 4. Disregards the password, check the UNIX socker instead
# Since we setup no password, it wouldn't let us connect to phpMyAdmin otherwise
echo "update mysql.user set plugin='' where user='root';" | mysql -u root --skip-password;

#------------------------------------------------------------------------------------------------------
# Restart the nginx to apply the changes
service nginx restart;

# Restart php to apply the changes
service php7.3-fpm restart;

# At this point the commands will be executed once and the server will shut down.
# We need to be able to keep our server running.
# There are multiple ways to achieve this, but here I will use a kind of a lazy solution of
# executing "sleep infinity" command which will simply keep our server running until we press CTRL+C
# in the terminal
sleep infinity

# Please note that since "sleep infinity" is executed while running our container,
# the "docker run" flags "-it" (= terminal mode with a "pretty" format) are not going to do anything anymore.
# If you still want to run your container in terminal mode, you can remove the "sleep infinity" command
# or simply replace "sleep infinity" with "bash" command
```

Now that all of the commands we need to execute are ready and waiting in "[start.sh](./srcs/start.sh)" file, let's place it in our
container and tell our Dockerfile to execute it when we run our container.

`CMD` command defines the default command which will be ran when we start our container.

There can only be one CMD per container but since we need to execute several commands when we start it up we just place all of them in our "start.sh" file.

Another possibility would be to include all of them in our `CMD` by separating them with `';'` but it would've been a hell of a line 😅

```Dockerfile
#----------------------------------- 5. PHP MY ADMIN ---------------------------------------------
# Move start.sh from our computer inside the container
COPY ./srcs/start.sh ./

# Every other command in Dockerfile is executed while "building" our container
# CMD tells Docker the default command to execute when we are "running" our container
CMD bash start.sh;
```

Now that we have created a database, let's download and configure phpMyAdmin to test it!

First, just as for NGINX, phpMyAdmin will need a configuration file to set up some basic behaviour.

[Here](https://docs.phpmyadmin.net/fr/latest/config.html) you can find all the information about the
values inside of the phpMyAdmin configuration file and [here](https://docs.phpmyadmin.net/fr/latest/config.html#config-examples)
you can find some examples.

I will be using a default configuration with all the commented out parts removed and with only
"blowfish secret", "host" and "AllowNoPassword" fields modified. 

Let's create a "[config.inc.php](./srcs/config.inc.php)" file in our "srcs" folder and add the following lines inside:

```PHP
<?php
/**
 * phpMyAdmin sample configuration, you can use it as base for
 * manual configuration. For easier setup you can use setup/
 *
 * All directives are explained in documentation in the doc/ folder
 * or at <https://docs.phpmyadmin.net/>.
 */

declare(strict_types=1);

/**
 * This is needed for cookie based authentication to encrypt password in
 * cookie. Needs to be 32 chars long.
 */
$cfg['blowfish_secret'] = 'abcdefghijklmnopqrstuvwxyz0123456789'; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */

/**
 * Servers configuration
 */
$i = 0;

/**
 * First server
 */
$i++;
/* Authentication type */
$cfg['Servers'][$i]['auth_type'] = 'cookie';
/* Server parameters */
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
/* This is needed to login to phpMyAdmin without the use of the password */
$cfg['Servers'][$i]['AllowNoPassword'] = true;

/**
 * Directories for saving/loading files from server
 */
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
```

Now that we have our phpMyAdmin configuration file ready, let's download phpMyAdmin and set everything up!

Add the following lines to our Dockerfile:

```Dockerfile
# Download phpMyAdmin by using "wget" which we installed in step 2
# At the time you do this you might need to download a different version from 5.1.0
# Try to always use the latest version
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.1.0/phpMyAdmin-5.1.0-english.tar.gz

# Extract the downloaded compressed files and remove the ".tar" file we no longer need
RUN tar -xf phpMyAdmin-5.1.0-english.tar.gz && rm -rf phpMyAdmin-5.1.0-english.tar.gz

# Rename the downloaded folder by "phpmyadmin"
RUN mv phpMyAdmin-5.1.0-english phpmyadmin

# Copy the "config.inc.php" file we created to the same "phpmyadmin" folder
COPY ./srcs/config.inc.php phpmyadmin
#-------------------------------------------------------------------------------------------------
```

Now if we try to build our docker image and run it we will obtain a container with phpMyAdmin configured and running
and also with an empty "wordpress" database created using MySQL. We no longer need to start up NGINX manually and
our website now looks different.

Our autoindex homepage will now look like this:

![](srcs/images/autoindex_phpmyAdmin.png)

By clicking on "phpmyadmin/" we will be able to login into phpMyAdmin using "root" login without a password:

![](srcs/images/phpMyAdmin_login.png)

Inside on the left side we will be able to see the "wordpress" database
we created earlier which is currently empty if we click on it.

This proves that phpMyAdmin is capable of reaching that database and is setup properly.

![](srcs/images/phpmyadmin_wp_db.png)

We can also see an error displying which is caused by access rights configuration of our phpMyAdmin files.

We will solve this issue in the next step by modifying the ownership and access rights of the files in our working directory.

![](srcs/images/phpmyadmin_error.png)

You can also note that if we disable the autoindex at this point, we will still get the same "403 Forbidden" error while trying to reach [localhost](https://localhost) webpage but we are able to reach phpMyAdmin by reaching [https://localhost/phpmyadmin/](https://localhost/phpmyadmin/)

This shows that the autoindex is only responsible for our "index of /" homepage.

Now we are almost at the end, the only thing we still need to do is install Wordpress. Let's go 💪

# Install and configure Wordpress
In the previous step we have already created and prepared a database for Wordpress with mySQL.

Now we will create a Wordpress configuration file, download Wordpress using "wget" and set it all up.

Just as with phpMyAdmin, I will be using a [default Wordpress configuration file](https://github.com/WordPress/WordPress/blob/master/wp-config-sample.php).

I will only modify the "DB_NAME", "DB_USER" and "DB_PASSWORD" fields to match our MySQL wordpress database values (defined in our "start.sh" file) and leave the rest of it as it is.

Let's start by creating a configuration file named "[wp-config.php](./srcs/wp-config.php)" in our "srcs" folder.

Add the following lines inside:
```php
<?php

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** MySQL database username */
define( 'DB_USER', 'root' );

/** MySQL database password */
define( 'DB_PASSWORD', '' );

/** MySQL hostname */
define( 'DB_HOST', 'localhost' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );
```

Now that we have our configuration file ready, let's download Wordpress and configure our container!

The procedure is very similar to phpMyAdmin.

The only things extra that we will add here are the commands `chown` and `chmod`.

These commands are used to solve the problem we had in phpMyAdmin in previous step, where
phpMyAdmin couldn't access certain required files.

Add the following lines in our Dockerfile:

```Dockerfile
#----------------------------- 5.Install and configure Wordpress ---------------------------------
# Download Wordpress using wget
RUN wget https://wordpress.org/latest.tar.gz

# Extract it and remove the .tar file
RUN tar -xvzf latest.tar.gz && rm -rf latest.tar.gz 

# Copy our configuration file inside the container
COPY ./srcs/wp-config.php /var/www/localhost/wordpress

# Change ownership and allow access to all the files
# This is required for phpMyAdmin to have acces to all the data, otherwise it will display an error
RUN chown -R www-data:www-data *
RUN chmod -R 755 /var/www/*
#-------------------------------------------------------------------------------------------------
```

And this is it, our project is 100% ready! 💯

Now we have a fully functional ft_server project with NGINX, MySQL (MariaDB), phpMyAdmin, Wordpress and SSL protocol!

If you build and run our container now, our autoindex homepage will look like this:

![](srcs/images/index.png)

Just as with phpMyAdmin, if you turn autoindex off, you will get a 403 Forbidden error when reaching [localhost](https://localhost) webpage
but you will be able to open wordpress by reaching [https://localhost/wordpress](https://localhost/wordpress)

The first time you open Wordpess, it will ask you to create a profile and afterwards you will be able to login with it and use all of the Wordpress features like themes, posts etc.

![](srcs/images/wordpress_install.png)

![](srcs/images/wordpress_admin.png)

Afterwards if you open phpMyAdmin and you click on the Wordpress database it will no longer be empty.

You will be able to see the user you created to access Wordpress and any new posts/pages you try to create in Wordpress.

(Note: If you didn't open and setup Wordpress before you got to phpMyAdmin, the "Wordpress" section is still going to be empty)

Since we changed the ownership and access rights of all the required files, the phpMyAdmin error we saw before should no longer be present.

![](srcs/images/phpmyadmin_wp_full.png)

You can check that the profile you created to access Wordpress is actually appearing in phpMyAdmin tables in "wordpress" -> "wp-users" section to make sure the link between the two is working properly.

The only thing left to do is upload it and schedule your corrections 😉

--------------------------------------------------------------------------------------------------------------------------------------

# The end

Congratulations on finishing the project and thank you for going through my tutorial 💪!

If you have any questions, issues or feedback, you can contact me by [filing an issue here](https://github.com/Ysoroko/ft_server_tutorial/issues)

If this tutorial helped you with your work, don't hesitate to "star ⭐" it on Github, it helps me a lot!

Good luck with your future projects! 👋

--------------------------------------------------------------------------------------------------------------------------------------

# Error checking
#### In case you complete this tutorial and you get any errors, you can find final versions of each file in this repository to compare them with yours.
#### Please avoid simply copy/pasting everything as there are a lot of handy new concepts you need to understand and use in a later project "ft_services".
* [Dockerfile](./Dockerfile)
* [localhost](./srcs/localhost)
* [start.sh](./srcs/start.sh)
* [config.inc.php](./srcs/config.inc.php)
* [wp-config.php](./srcs/wp-config.php)
* (Optional but helpful: [Makefile](./Makefile))

--------------------------------------------------------------------------------------------------------------------------------------

# Useful links:
- [**Udemy course as a useful introduction to Docker**](https://www.udemy.com/course/docker-and-kubernetes-the-complete-guide/)
- [**How to install LEMP stack on Debian 10**](https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mariadb-php-lemp-stack-on-debian-10)
- [**Wordpress and phpMyAdmin setup with Docker on Alpine**](https://codingwithmanny.medium.com/custom-wordpress-docker-setup-8851e98e6b8)
- [**Generating a self signed SSL key**](https://linuxize.com/post/creating-a-self-signed-ssl-certificate/)
- [**Incomplete project guide by a 42 student (part 1)**](https://forhjy.medium.com/how-to-install-lemp-wordpress-on-debian-buster-by-using-dockerfile-1-75ddf3ede861)
- [**Incomplete project guide by a 42 student (part 2)**](https://forhjy.medium.com/42-ft-server-how-to-install-lemp-wordpress-on-debian-buster-by-using-dockerfile-2-4042adb2ab2c)
- [**PhpMyAdmin configuration file values explained**](https://docs.phpmyadmin.net/fr/latest/config.html)
- [**PhpMyAdmin configuration file default example**](https://docs.phpmyadmin.net/fr/latest/config.html#config-examples)
- [**Wordpress default configuration file**](https://github.com/WordPress/WordPress/blob/master/wp-config-sample.php)
- [**How to edit Wordpress configuration file**](https://www.wpbeginner.com/beginners-guide/how-to-edit-wp-config-php-file-in-wordpress/)

--------------------------------------------------------------------------------------------------------------------------------------
