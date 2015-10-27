# server setup tool

This script is use for setup Linux server and some apps.
(Now only for CentOS and Flockbird)

-----------
How to use
-----------

###　1. set config file ###
* Copy config file from sample and edit it for your enviroment

~~~
# cp setup.conf.sample setup.conf
# vi setup.conf
~~~


### 2. execute script creating admin_user ####
* You have to execute by root user.

~~~
# sh execute_create_admin_user.sh
~~~


### 3. execute system setup script ####
* Connect by ssh and login admin user.
* It's better to start screen connection before executing system setup script.
* Execute below command.
    + You have to execute by sudo.

~~~
$ sudo sh execute_setup.sh
~~~
