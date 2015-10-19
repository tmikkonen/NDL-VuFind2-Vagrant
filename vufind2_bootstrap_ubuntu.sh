#!/usr/bin/env bash

# VuFind2 'install path' ie. mount path of the host's shared folder, Solr index URL
INSTALL_PATH='/usr/local/vufind2'
SOLR_URL='http://localhost:8080/solr'
#SAMPLE_DATA_PATH=''  # eg. /vagrant/violasample.xml, use MARC!

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='root' # change this to your liking
DATABASE='vufind2'
USER='vufind'
USER_PW='vufind'
TIMEZONE='Europe/Helsinki'

# set timezone
sudo timedatectl set-timezone $TIMEZONE

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install apache 2.5
sudo apt-get install -y apache2

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server

# create database and user & modify database
MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DATABASE;"
Q2="GRANT ALL ON $DATABASE.* TO '$USER'@'localhost' IDENTIFIED BY '$USER_PW';"
Q3="FLUSH PRIVILEGES;"
Q4="USE $DATABASE;"
Q5="SOURCE $INSTALL_PATH/module/VuFind/sql/mysql.sql;"
Q6="SOURCE $INSTALL_PATH/module/Finna/sql/mysql.sql;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
$MYSQL -uroot -p$PASSWORD -e "$SQL"

# install php 5.5
sudo apt-get install -y php5 php5-dev php-pear php5-json php5-mcrypt php5-mysql php5-xsl php5-intl php5-gd

# change php.ini: display_errors = On, opcache.enable=0
sudo sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php5/apache2/php.ini
sudo sed -i -e 's/;opcache.enable=0/opcache.enable=0/' /etc/php5/apache2/php.ini

# install Java JDK
sudo apt-get -y install default-jdk

# enable mod_rewrite
sudo a2enmod rewrite

# link VuFind to Apache
sudo cp -f $INSTALL_PATH/local/httpd-vufind.conf.sample /etc/apache2/conf-available/httpd-vufind.conf
sudo sed -i -e 's,/path-to/NDL-VuFind2,'"$INSTALL_PATH"',' /etc/apache2/conf-available/httpd-vufind.conf
if [ ! -h /etc/apache2/conf-enabled/vufind2.conf ]; then
  sudo ln -s /etc/apache2/conf-available/httpd-vufind.conf /etc/apache2/conf-enabled/vufind2.conf
fi

# copy sample configs to ini files
cd $INSTALL_PATH/local/config/finna
for x in *.ini.sample; do 
  t=${x%.ini.sample}.ini
  if [ ! -f $t ]; then
    cp $x $t
  fi
done

cd $INSTALL_PATH/local/config/vufind
for x in *ini.sample; do 
  t=${x%.ini.sample}.ini
  if [ ! -f $t ]; then
    cp $x $t
  fi
done
cp searchspecs.yaml.sample searchspecs.yaml
cd
# modify Solr URL if set
if [ ! -z "$SOLR_URL" ]; then
  sudo sed -i -e 's,;url *= *\n,url = '"$SOLR_URL"',' $INSTALL_PATH/local/config/vufind/config.ini
fi

# copy local dir inside virtual machine
sudo mkdir -p /usr/local/vufind2_local
sudo cp -rf $INSTALL_PATH/local/* /usr/local/vufind2_local/
sudo sed -i -e 's,VUFIND_LOCAL_DIR '"$INSTALL_PATH"'/local,VUFIND_LOCAL_DIR /usr/local/vufind2_local,' /etc/apache2/conf-available/httpd-vufind.conf
sudo chown -R vagrant:vagrant /usr/local/vufind2_local
sudo chown -R www-data:www-data /usr/local/vufind2_local/cache

# restart apache
service apache2 restart

# create log file and change owner
sudo touch /var/log/vufind2.log
sudo chown www-data:www-data /var/log/vufind2.log

# run local Solr?
if [ "$SOLR_URL" = "http://localhost:8080/solr" ]; then
  sudo $INSTALL_PATH/vufind.sh start
#  if [ -z "$SAMPLE_DATA_PATH" ]; then
#    sudo $INSTALL_PATH/import-marc.sh $SAMPLE_DATA_PATH
#  fi
fi

