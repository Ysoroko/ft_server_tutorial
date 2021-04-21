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

# At this point the commands will be executed once and that's it, we need to be able to keep our server
# running. There are multiple ways to achieve this, but here I will use a kind of a lazy solution of
# executing "sleep infinity" command which will simply keep our server running until we press CTRL+C
sleep infinity

# Please note that since "sleep infinity" is executed while running our container,
# the "docker run" flags "-it" (= terminal mode with a "pretty" format) are not going to do anything anymore.
# If you still want to run your container in terminal mode, you can remove the "sleep infinity" command
