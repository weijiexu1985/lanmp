#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

if [ $(id -u) != "0" ]; then
printf "Error: You must be root to run this script!"
exit 1
fi

LANMMP_PATH=`pwd`
if [ `echo $LANMMP_PATH | awk -F/ '{print $NF}'` != "lanmmp" ]; then
clear && echo "Please enter LANMMP script path:"
read -p "(Default path: ${LANMMP_PATH}/lanmmp):" LANMMP_PATH
[ -z "$LANMMP_PATH" ] && LANMMP_PATH=$(pwd)/LANMMP
cd $LANMMP_PATH/
fi

clear
echo "#############################################################"
echo "# Linux + Apache + Nginx + MariaDB + PHP Auto Install Script"
echo "# Env: Redhat/CentOS"
echo "# Intro: "
echo "# Version: $(awk '/version/{print $2}' $LANMMP_PATH/Changelog)"
echo "#"
echo "# Copyright (c) 2014, weijiexu <weijiexu1985@163.com>"
echo "# WangYan lanmp modification based on,Thanks wangyan"
echo "# All rights reserved."
echo "# Distributed under the GNU General Public License, version 1.0."
echo "#"
echo "#############################################################"
echo ""

echo "Please enter the server IP address:"
TEMP_IP=`ifconfig |grep 'inet' | grep -Evi '(inet6|127.0.0.1)' | awk '{print $2}' | cut -d: -f2 | tail -1`
read -p "(e.g: $TEMP_IP):" IP_ADDRESS
if [ -z $IP_ADDRESS ]; then
IP_ADDRESS="$TEMP_IP"
fi
echo "---------------------------"
echo "IP address = $IP_ADDRESS"
echo "---------------------------"
echo ""

echo "Please enter the webroot dir:"
read -p "(Default webroot dir: /var/www):" WEBROOT
if [ -z $WEBROOT ]; then
WEBROOT="/var/www"
fi
echo "---------------------------"
echo "Webroot dir=$WEBROOT"
echo "---------------------------"
echo ""

echo "Please enter the MySQL root password:"
read -p "(Default password: 123456):" MYSQL_ROOT_PWD
if [ -z $MYSQL_ROOT_PWD ]; then
MYSQL_ROOT_PWD="123456"
fi
echo "---------------------------"
echo "MySQL root password = $MYSQL_ROOT_PWD"
echo "---------------------------"
echo ""

echo "Please enter the MySQL pma password:"
read -p "(Default password: 123456):" PMAPWD
if [ -z $PMAPWD ]; then
PMAPWD="123456"
fi
echo "---------------------------"
echo "PMA password = $PMAPWD"
echo "---------------------------"
echo ""

echo "Please choose webserver software! (1:nginx,2:apache,3:nginx+apache) (1/2/3)"
read -p "(Default: 3):" SOFTWARE
if [ -z $SOFTWARE ]; then
SOFTWARE="3"
fi
echo "---------------------------"
echo "You choose = $SOFTWARE"
echo "---------------------------"
echo ""

echo "Please choose moodle version! (1:moodle2.6,2:moodle2.7) (1/2)"
read -p "(Default: 1):" M_VERSION
if [ -z $M_VERSION ]; then
M_VERSION="1"
fi
echo "---------------------------"
echo "You choose = $M_VERSION"
echo "---------------------------"
echo ""

echo "Do you want to initialize aliyun ? (y/n)"
read -p "(Default: n):" INIT_ALIYUN
if [ -z $INIT_ALIYUN ]; then
INIT_ALIYUN="n"
fi
echo "---------------------------"
echo "You choose = $INIT_ALIYUN"
echo "---------------------------"
echo ""

echo "Do you want to install opcache ? (y/n)"
read -p "(Default: y):" INSTALL_XC
if [ -z $INSTALL_OC ]; then
INSTALL_OC="y"
fi
echo "---------------------------"
echo "You choose = $INSTALL_OC"
echo "---------------------------"
echo ""


get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
echo "Press any key to start install..."
echo "Or Ctrl+C cancel and exit ?"
echo ""
char=`get_char`

echo "---------- Network Check ----------"

ping -c 1 baidu.com &>/dev/null && PING=1 || PING=0

if [ -d "$LANMMP_PATH/src" ];then
\mv $LANMMP_PATH/src/* $LANMMP_PATH
fi

if [ "$PING" = 0 ];then
echo "Network Failed!"
[ ! -s mysql-*.tar.gz ] && exit
else
echo "Network OK"
fi

echo "---------- Aliyun Initialize ----------"

if [ "$INIT_ALIYUN" = "y" ]; then
$LANMMP_PATH/aliyun_init.sh
fi

echo "---------- Remove Packages ----------"

yum -y remove httpd
yum -y remove mysql
yum -y remove php
yum -y update

if [ ! -s /etc/yum.conf.bak ]; then
cp /etc/yum.conf /etc/yum.conf.bak
fi
sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf

echo "---------- Set timezone ----------"

rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

yum -y install ntp
[ "$PING" = 1 ] && ntpdate -d cn.pool.ntp.org

echo "---------- Disable SeLinux ----------"

if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

echo "---------- Set Library ----------"

if [ ! `grep -iqw /lib /etc/ld.so.conf` ]; then
echo "/lib" >> /etc/ld.so.conf
fi

if [ ! `grep -iqw /usr/lib /etc/ld.so.conf` ]; then
echo "/usr/lib" >> /etc/ld.so.conf
fi

if [ -d "/usr/lib64" ] && [ ! `grep -iqw /usr/lib64 /etc/ld.so.conf` ]; then
echo "/usr/lib64" >> /etc/ld.so.conf
fi

if [ ! `grep -iqw /usr/local/lib /etc/ld.so.conf` ]; then
echo "/usr/local/lib" >> /etc/ld.so.conf
fi

ldconfig

echo "---------- Set Environment ----------"

if [ "$INIT_ALIYUN" != "y" ];then
cat >>/etc/security/limits.conf<<-EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
ulimit -v unlimited

cat >>/etc/sysctl.conf<<-EOF
fs.file-max=65535
EOF
sysctl -p
fi

echo "---------- Dependent Packages ----------"

yum -y install make cmake autoconf autoconf213 gcc gcc-c++ libtool
yum -y install wget elinks bison patch unzip tar
yum -y install openssl openssl-devel
yum -y install zlib zlib-devel
yum -y install freetype freetype-devel
yum -y install libxml2 libxml2-devel
yum -y install libdhash libdhash-devel
yum -y install curl curl-devel
yum -y install xmlrpc-c xmlrpc-c-devel
yum -y install libevent libevent-devel
yum -y install ncurses ncurses-devel
yum -y install libc-client libc-client-devel libicu-devel

####################### Extract Function ########################

Extract(){
local TARBALL_TYPE
if [ -n $1 ]; then
  SOFTWARE_NAME=`echo $1 | awk -F/ '{print $NF}'`
  TARBALL_TYPE=`echo $1 | awk -F. '{print $NF}'`
  wget -c -t3 -T3 $1 -P $LANMMP_PATH/
   if [ $? != "0" ];then
     rm -rf $LANMMP_PATH/$SOFTWARE_NAME
     wget -c -t3 -T60 $2 -P $LANMMP_PATH/
     SOFTWARE_NAME=`echo $2 | awk -F/ '{print $NF}'`
     TARBALL_TYPE=`echo $2 | awk -F. '{print $NF}'`
   fi
else
  SOFTWARE_NAME=`echo $2 | awk -F/ '{print $NF}'`
  TARBALL_TYPE=`echo $2 | awk -F. '{print $NF}'`
  wget -c -t3 -T3 $2 -P $LANMMP_PATH/ || exit
fi
EXTRACTED_DIR=`tar tf $LANMMP_PATH/$SOFTWARE_NAME | tail -n 1 | awk -F/ '{print $1}'`
case $TARBALL_TYPE in
  gz|tgz)
tar zxf $LANMMP_PATH/$SOFTWARE_NAME -C $LANMMP_PATH/ && cd $LANMMP_PATH/$EXTRACTED_DIR || return 1
;;
  bz2|tbz)
tar jxf $LANMMP_PATH/$SOFTWARE_NAME -C $LANMMP_PATH/ && cd $LANMMP_PATH/$EXTRACTED_DIR || return 1
;;
  tar|Z)
tar xf $LANMMP_PATH/$SOFTWARE_NAME -C $LANMMP_PATH/ && cd $LANMMP_PATH/$EXTRACTED_DIR || return 1
;;
*)
echo "$SOFTWARE_NAME is wrong tarball type ! "
esac
    }

echo "===================== MariaDB Install ===================="

cd $LANMMP_PATH/
rm -rf /etc/my.cnf /etc/mysql/

groupadd mysql
useradd -g mysql -M -s /bin/false mysql

if [ ! -s mariadb-*.tar.gz ]; then
   LATEST_MYSQL_LINK="http://www.hnsssy.com/download/software/mariadb-latest.tar.gz"
   BACKUP_MYSQL_LINK="https://downloads.mariadb.org/f/mariadb-10.0.11/source/mariadb-10.0.11.tar.gz?serve"
   Extract ${LATEST_MYSQL_LINK} ${BACKUP_MYSQL_LINK}
else
   tar -zxf mariadb-*.tar.gz
   cd mariadb-*/
fi

cmake . \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/usr/local/mysql/data  \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DENABLE_DOWNLOADS=0
make install

#cd ../
#cp conf/my.cnf /etc/my.cnf


cd /usr/local/mysql
cp support-files/my-large.cnf /etc/my.cnf

cat >>//etc/my.cnf<<-EOF
datadir = /usr/local/mysql/data
EOF

sed -i 's,thread_concurrency = 8,thread_concurrency = 2,g' /etc/my.cnf
scripts/mysql_install_db --user=mysql
cp support-files/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
chown -R root:root /usr/local/mysql/.
chown -R mysql /usr/local/mysql/data
sed -i 's,basedir =,basedir = /usr/local/mysql,g' /etc/init.d/mysql
sed -i 's,datadir =,datadir = /data/mysql,g' /etc/init.d/mysql
chkconfig mysql on

if [ ! `grep -iqw /usr/local/mysql/lib /etc/ld.so.conf` ]; then
  echo "/usr/local/mysql/lib" >> /etc/ld.so.conf
fi
ldconfig

cd /usr/local/mysql/bin
for i in *; do ln -s /usr/local/mysql/bin/$i /usr/bin/$i; done

/etc/init.d/mysql start
/usr/local/mysql/bin/mysqladmin -u root password $MYSQL_ROOT_PWD

echo "===================== Apache Install ===================="

if [ "$SOFTWARE" != "1" ]; then

   echo "---------- Apache ----------"

   cd $LANMMP_PATH/

     if [ ! -s httpd-*.tar.gz ]; then
       LATEST_APACHE_LINK="https://gitcafe.com/wangyan/files/raw/master/httpd-2.2.24.tar.gz"
       BACKUP_APACHE_LINK="http://www.hnsssy.com/download/software/httpd-2.2.24.tar.gz"
       Extract ${LATEST_APACHE_LINK} ${BACKUP_APACHE_LINK}
     else
       tar -zxf httpd-*.tar.gz
       cd httpd-*/
     fi

  ./configure --prefix=/usr/local/apache --enable-mods-shared=most --enable-ssl=shared --with-mpm=prefork
  make && make install

  echo "---------- Apache config ----------"

  cd $LANMMP_PATH/

  groupadd www
  useradd -g www -M -s /bin/false www

  for i in `ls /usr/local/apache/bin/`; do ln -s /usr/local/apache/bin/$i /usr/bin/$i; done

  cp conf/init.d.httpd /etc/init.d/httpd
  chmod 755 /etc/init.d/httpd
  chkconfig httpd on

  mv /usr/local/apache/conf/httpd.conf /usr/local/apache/conf/httpd.conf.old
  cp conf/httpd.conf /usr/local/apache/conf/httpd.conf
  chmod 644 /usr/local/apache/conf/httpd.conf

  mv /usr/local/apache/conf/extra/httpd-mpm.conf /usr/local/apache/conf/extra/httpd-mpm.conf.bak
  cp conf/httpd-mpm.conf /usr/local/apache/conf/extra/httpd-mpm.conf
  chmod 644 /usr/local/apache/conf/extra/httpd-mpm.conf

  mkdir /usr/local/apache/conf/vhosts
  chmod 711 /usr/local/apache/conf/vhosts
  mkdir -p $WEBROOT
  cp conf/p.php $WEBROOT

  echo "---------- Apache SSL ----------"

  cd $LANMMP_PATH/

  mkdir /usr/local/apache/conf/ssl
  chmod 711 /usr/local/apache/conf/ssl
  cp conf/server* /usr/local/apache/conf/ssl
  chmod 644 /usr/local/apache/conf/ssl/*

  mv /usr/local/apache/conf/extra/httpd-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf.bak
  cp conf/httpd-ssl.conf /usr/local/apache/conf/extra/httpd-ssl.conf
  chmod 644 /usr/local/apache/conf/extra/httpd-ssl.conf
  sed -i 's,WEBROOT,'$WEBROOT',g' /usr/local/apache/conf/extra/httpd-ssl.conf

    if [ "$SOFTWARE" = "2" ]; then
     sed -i 's,#Include conf/extra/httpd-s,Include conf/extra/httpd-s,g' /usr/local/apache/conf/httpd.conf
    fi

  echo "---------- Apache frontend ----------"

    if [ "$SOFTWARE" = "2" ]; then
      sed -i 's/\#Listen 80/Listen 80/g' /usr/local/apache/conf/httpd.conf
cat >/usr/local/apache/conf/extra/httpd-vhosts.conf<<-EOF
NameVirtualHost *:80

<VirtualHost _default_:80>
ServerAdmin webmaster@example.com
DocumentRoot "$WEBROOT"
ServerName 127.0.0.1
ErrorLog "logs/error_log"
CustomLog "logs/access_log" combinedio
<Directory "$WEBROOT">
Options +Includes +Indexes
php_admin_flag engine ON
php_admin_value open_basedir "$WEBROOT:/tmp:/proc:/data"
</Directory>
</VirtualHost>

Include /usr/local/apache/conf/vhosts/*.conf
EOF
    fi

  echo "---------- Apache backend ----------"

  cd $LANMMP_PATH/

    if [ "$SOFTWARE" = "3" ]; then

       echo "---------- RPAF Moudle ----------"

       if [ ! -s mod_rpaf-*.tar.gz ]; then
        LATEST_RPAF_LINK="https://gitcafe.com/wangyan/files/raw/master/mod_rpaf-0.6.tar.gz"
        BACKUP_RPAF_LINK="http://www.hnsssy.com/download/software/mod_rpaf-latest.tar.gz"
        Extract ${LATEST_RPAF_LINK} ${BACKUP_RPAF_LINK}
       else
        tar zxf mod_rpaf-*.tar.gz
        cd mod_rpaf-*/
       fi
    /usr/local/apache/bin/apxs -i -c -n mod_rpaf-2.0.so mod_rpaf-2.0.c

    sed -i 's/\#Listen 127/Listen 127/g' /usr/local/apache/conf/httpd.conf
    sed -i 's/\#LoadModule rpaf/LoadModule rpaf/g' /usr/local/apache/conf/httpd.conf

    echo "---------- Backend Config ----------"

cat >/usr/local/apache/conf/extra/httpd-vhosts.conf<<-EOF
NameVirtualHost 127.0.0.1:8080

<VirtualHost 127.0.0.1:8080>
ServerAdmin webmaster@example.com
DocumentRoot "$WEBROOT"
ServerName 127.0.0.1
ErrorLog "logs/error_log"
CustomLog "logs/access_log" combinedio
<Directory "$WEBROOT">
Options +Includes +Indexes
php_admin_flag engine ON
php_admin_value open_basedir "$WEBROOT:/tmp:/proc:/data"
</Directory>
</VirtualHost>

Include /usr/local/apache/conf/vhosts/*.conf
EOF
     fi
 fi

echo "===================== PHP5 Install ===================="

echo "---------- libpng ----------"

cd $LANMMP_PATH/

if [ ! -s libpng-*.tar.gz ]; then
LATEST_LIBPNG_LINK="https://gitcafe.com/wangyan/files/raw/master/libpng-1.6.3.tar.gz"
BACKUP_LIBPNG_LINK="http://www.hnsssy.com/download/software/libpng-latest.tar.gz"
Extract ${LATEST_LIBPNG_LINK} ${BACKUP_LIBPNG_LINK}
else
tar -zxf libpng-*.tar.gz
cd libpng-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libjpeg ----------"

cd $LANMMP_PATH/

if [ ! -s jpegsrc.*.tar.gz ]; then
LATEST_LIBJPEG_LINK="https://gitcafe.com/wangyan/files/raw/master/jpegsrc.v9.tar.gz"
BACKUP_LIBJPEG_LINK="http://www.hnsssy.com/download/software/jpegsrc.latest.tar.gz"
Extract ${LATEST_LIBJPEG_LINK} ${BACKUP_LIBJPEG_LINK}
else
tar -zxf jpegsrc.*.tar.gz
cd jpeg-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libiconv ----------"

cd $LANMMP_PATH/

if [ ! -s libiconv-*.tar.gz ]; then
LATEST_LIBICONV_LINK="https://gitcafe.com/wangyan/files/raw/master/libiconv-1.14.tar.gz"
BACKUP_LIBICONV_LINK="http://www.hnsssy.com/download/software/libiconv-latest.tar.gz"
Extract ${LATEST_LIBICONV_LINK} ${BACKUP_LIBICONV_LINK}
else
tar -zxf libiconv-*.tar.gz
cd libiconv-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- libmcrypt ----------"

cd $LANMMP_PATH/

if [ ! -s libmcrypt-*.tar.gz ]; then
LATEST_LIBMCRYPT_LINK="https://gitcafe.com/wangyan/files/raw/master/libmcrypt-2.5.8.tar.gz"
BACKUP_LIBMCRYPT_LINK="http://www.hnsssy.com/download/software/libmcrypt-latest.tar.gz"
Extract ${LATEST_LIBMCRYPT_LINK} ${BACKUP_LIBMCRYPT_LINK}
else
tar -zxf libmcrypt-*.tar.gz
cd libmcrypt-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- mhash ----------"

cd $LANMMP_PATH/

if [ ! -s mhash-*.tar.gz ]; then
LATEST_MHASH_LINK="https://gitcafe.com/wangyan/files/raw/master/mhash-0.9.9.9.tar.gz"
BACKUP_MHASH_LINK="http://www.hnsssy.com/download/software/mhash-latest.tar.gz"
Extract ${LATEST_MHASH_LINK} ${BACKUP_MHASH_LINK}
else
tar -zxf mhash-*.tar.gz
cd mhash-*/
fi
./configure --prefix=/usr/local
make && make install && ldconfig

echo "---------- mcrypt ----------"

cd $LANMMP_PATH/

if [ ! -s mcrypt-*.tar.gz ]; then
LATEST_MCRYPT_LINK="https://gitcafe.com/wangyan/files/raw/master/mcrypt-2.6.8.tar.gz"
BACKUP_MCRYPT_LINK="http://www.hnsssy.com/download/software/mcrypt-latest.tar.gz"
Extract ${LATEST_MCRYPT_LINK} ${BACKUP_MCRYPT_LINK}
else
tar -zxf mcrypt-*.tar.gz
cd mcrypt-*/
fi
./configure --prefix=/usr/local
make && make install

echo "---------- php5 ----------"

cd $LANMMP_PATH/

groupadd www
useradd -g www -M -s /bin/false www

if [ ! -s php-5.5*.tar.gz ]; then
LATEST_PHP_VERSION=`curl -s http://php.net/downloads.php | awk '/Current Stable/{print $3}'`
LATEST_PHP_LINK="http://php.net/distributions/php-${LATEST_PHP_VERSION}.tar.gz"
BACKUP_PHP_LINK="http://www.hnsssy.com/download/software/php-5.5-latest.tar.gz"
Extract ${LATEST_PHP_LINK} ${BACKUP_PHP_LINK}
else
tar -zxf php-5.5*.tar.gz
cd php-5.5*/
fi
# fi

if [ "$SOFTWARE" = "1" ]; then
./configure \
--prefix=/usr/local/php \
--with-curl \
--with-freetype-dir \
--with-gettext \
--with-gd \
--with-iconv-dir \
--with-jpeg-dir \
--with-libxml-dir \
--with-mcrypt \
--with-mhash \
--with-mysql=/usr/local/mysql \
--with-mysqli=/usr/local/mysql/bin/mysql_config \
--with-openssl \
--with-pear \
--with-png-dir \
--with-xmlrpc \
--with-zlib \
--enable-bcmath \
--enable-calendar \
--enable-exif \
--enable-fpm \
--enable-ftp \
--enable-gd-native-ttf \
--enable-inline-optimization \
--enable-mbregex \
--enable-mbstring \
--enable-pcntl \
--enable-shmop \
--enable-soap \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-xml \
--enable-zip  \
--enable-opcache  \
--enable-intl  
else
./configure \
--prefix=/usr/local/php \
--with-apxs2=/usr/local/apache/bin/apxs \
--with-curl \
--with-curlwrappers \
--with-freetype-dir \
--with-gettext \
--with-gd \
--with-iconv-dir \
--with-jpeg-dir \
--with-libxml-dir \
--with-mcrypt \
--with-mhash \
--with-mysql=/usr/local/mysql \
--with-mysqli=/usr/local/mysql/bin/mysql_config \
--with-openssl \
--with-pear \
--with-png-dir \
--with-xmlrpc \
--with-zlib \
--enable-bcmath \
--enable-calendar \
--enable-exif \
--enable-ftp \
--enable-gd-native-ttf \
--enable-inline-optimization \
--enable-mbregex \
--enable-mbstring \
--enable-shmop \
--enable-soap \
--enable-sockets \
--enable-sysvsem \
--enable-sysvshm \
--enable-xml \
--enable-zip   \
--enable-intl  \
--enable-opcache
fi

make ZEND_EXTRA_LIBS='-liconv'
make install

echo "---------- PDO MYSQL Extension ----------"

cd ext/pdo_mysql/
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-pdo-mysql=/usr/local/mysql
make && make install

echo "---------- Memcache Extension ----------"

cd $LANMMP_PATH/

if [ ! -s memcache-*.tgz ]; then
LATEST_MEMCACHE_LINK="https://gitcafe.com/wangyan/files/raw/master/memcache-2.2.6.tgz"
BACKUP_MEMCACHE_LINK="http://www.hnsssy.com/download/software/memcache-latest.tgz"
Extract ${LATEST_MEMCACHE_LINK} ${BACKUP_MEMCACHE_LINK}
else
tar -zxf memcache-*.tgz
cd memcache-*/
fi
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-zlib-dir --enable-memcache
make && make install

echo "---------- PHP Config ----------"

cd $LANMMP_PATH/

for i in `ls /usr/local/php/bin`; do ln -s /usr/local/php/bin/$i /usr/bin/$i; done


cp php-*/php.ini-production /usr/local/php/lib/php.ini
sed -i 's#; extension_dir = "./"#extension_dir = "/usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/"\nextension = "memcache.so"\nextension = "pdo_mysql.so"\n#g' /usr/local/php/lib/php.ini

sed -i 's/short_open_tag = Off/short_open_tag = On/g' /usr/local/php/lib/php.ini
sed -i 's/disable_functions =/disable_functions = system,passthru,exec,shell_exec,popen,symlink,dl/g' /usr/local/php/lib/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 600/g' /usr/local/php/lib/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 300M/g' /usr/local/php/lib/php.ini
sed -i 's/magic_quotes_gpc = Off/magic_quotes_gpc = On/g' /usr/local/php/lib/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php/lib/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 200M/g' /usr/local/php/lib/php.ini
sed -i 's#;date.timezone =#date.timezone = Asia/Shanghai#g' /usr/local/php/lib/php.ini
sed -i 's#;sendmail_path =#sendmail_path = /usr/sbin/sendmail -t -i#g' /usr/local/php/lib/php.ini

if [ "$SOFTWARE" = "1" ]; then
cp php-5.5.*/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod 755 /etc/init.d/php-fpm
chkconfig php-fpm on
cp conf/php-fpm-p4.conf /usr/local/php/etc/php-fpm.conf
/etc/init.d/php-fpm start
else
/etc/init.d/httpd start
fi

echo "---------- opcache Extension ----------"

cd $LANMMP_PATH/

if [ "$INSTALL_OC" = "y" ];then
cat >>/usr/local/php/lib/php.ini<<-EOF

[opcache]
zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20121212/opcache.so
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=1
opcache.fast_shutdown=1

EOF
/etc/init.d/php-fpm restart
fi

echo "===================== Nginx Install ===================="

if [ "$SOFTWARE" != "2" ]; then

groupadd www
useradd -g www -M -s /bin/false www

echo "---------- Pcre ----------"

cd $LANMMP_PATH/

if [ ! -s pcre-*.tar.gz ]; then
LATEST_PCRE_LINK="https://gitcafe.com/wangyan/files/raw/master/pcre-8.33.tar.gz"
BACKUP_PCRE_LINK="http://www.hnsssy.com/download/software/pcre-latest.tar.gz"
Extract ${LATEST_PCRE_LINK} ${BACKUP_PCRE_LINK}
else
tar -zxf pcre-*.tar.gz
cd pcre-*/
fi
./configure
make && make install && ldconfig

echo "---------- Nginx ----------"

cd $LANMMP_PATH/
mkdir -p /var/tmp/nginx

if [ ! -s nginx-*.tar.gz ]; then
LATEST_NGINX_VERSION=`curl -s http://nginx.org/| awk -F- '/nginx-/{print $6}' | head -1|cut -d '<' -f 1`
LATEST_NGINX_LINK="http://nginx.org/download/nginx-${LATEST_NGINX_VERSION}.tar.gz"
BACKUP_NGINX_LINK="http://www.hnsssy.com/download/software/nginx-latest.tar.gz"
Extract ${LATEST_NGINX_LINK} ${BACKUP_NGINX_LINK}
else
tar -zxf nginx-*.tar.gz
cd nginx-*/
fi

./configure \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--user=www \
--group=www \
--with-http_ssl_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_realip_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--with-mail \
--with-mail_ssl_module \
--with-pcre \
--with-debug \
--with-ipv6 \
--http-client-body-temp-path=/var/tmp/nginx/client \
--http-proxy-temp-path=/var/tmp/nginx/proxy \
--http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
--http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
--http-scgi-temp-path=/var/tmp/nginx/scgi
make && make install

echo "---------- Nginx Config----------"

cd $LANMMP_PATH/
mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
cp conf/nginx.conf /usr/local/nginx/conf/nginx.conf
chmod 644 /usr/local/nginx/conf/nginx.conf

mkdir /usr/local/nginx/conf/ssl
chmod 711 /usr/local/nginx/conf/ssl
cp conf/server* /usr/local/nginx/conf/ssl/
chmod 644 /usr/local/nginx/conf/ssl/*

mkdir /usr/local/nginx/conf/vhosts
chmod 711 /usr/local/nginx/conf/vhosts
mkdir /usr/local/nginx/logs/localhost

if [ "$SOFTWARE" = "1" ]; then
cp conf/nginx-vhost-original.conf /usr/local/nginx/conf/vhosts/localhost.conf
else
cp conf/nginx-vhost-localhost.conf /usr/local/nginx/conf/vhosts/localhost.conf
cp conf/proxy_cache.inc /usr/local/nginx/conf/proxy_cache.inc
fi
chmod 644 /usr/local/nginx/conf/vhosts/localhost.conf
sed -i 's,www.DOMAIN,,g' /usr/local/nginx/conf/vhosts/localhost.conf
sed -i 's,DOMAIN/,localhost/,g' /usr/local/nginx/conf/vhosts/localhost.conf
sed -i 's,DOMAIN,'$IP_ADDRESS',g' /usr/local/nginx/conf/vhosts/localhost.conf
sed -i 's,ROOTDIR,'$WEBROOT',g' /usr/local/nginx/conf/vhosts/localhost.conf

if [ ! -d $WEBROOT ]; then
mkdir -p $WEBROOT
fi
\cp conf/p.php $WEBROOT

cp conf/init.d.nginx /etc/init.d/nginx
chmod 755 /etc/init.d/nginx
chkconfig nginx on

ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
/etc/init.d/nginx stop
/etc/init.d/nginx start
fi

echo "================phpMyAdmin Install==============="

cd $LANMMP_PATH/
/etc/init.d/mysql restart

if [ ! -s phpMyAdmin-*-all-languages.tar.gz ]; then
PMA_VERSION=`elinks http://nchc.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/ | awk -F/ '{print $7F}' | sort -n | grep -iv '-' | tail -1`
PMA_LINK="http://nchc.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/"
LATEST_PMA_LINK="${PMA_LINK}${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz"
BACKUP_PMA_LINK="http://www.hnsssy.com/download/software/phpMyAdmin-latest-all-languages.tar.gz"
Extract ${LATEST_PMA_LINK} ${BACKUP_PMA_LINK}
mkdir -p $WEBROOT/phpmyadmin
mv * $WEBROOT/phpmyadmin
else
PMA_VERSION=`ls phpMyAdmin-*-all-languages.tar.gz | awk -F- '{print $2}'`
tar -zxf phpMyAdmin-*-all-languages.tar.gz -C $WEBROOT
mv $WEBROOT/phpMyAdmin-*-all-languages $WEBROOT/phpmyadmin
fi

cd $LANMMP_PATH/
cp conf/config.inc.php $WEBROOT/phpmyadmin/config.inc.php
sed -i 's/PMAPWD/'$PMAPWD'/g' $WEBROOT/phpmyadmin/config.inc.php

cp conf/control_user.sql /tmp/control_user.sql
sed -i 's/PMAPWD/'$PMAPWD'/g' /tmp/control_user.sql
/usr/local/mysql/bin/mysql -u root -p$MYSQL_ROOT_PWD -h localhost < /tmp/control_user.sql

if [ -s $WEBROOT/phpmyadmin/scripts/create_tables.sql ]; then
cp $WEBROOT/phpmyadmin/scripts/create_tables.sql /tmp/create_tables.sql
else
cp $WEBROOT/phpmyadmin/examples/create_tables.sql /tmp/create_tables.sql
sed -i 's/pma__/pma_/g' $WEBROOT/phpmyadmin/examples/create_tables.sql
fi

/usr/local/mysql/bin/mysql -u root -p$MYSQL_ROOT_PWD -h localhost < $WEBROOT/phpmyadmin/examples/create_tables.sql

rm -rf /usr/local/mysql/data/test/

echo -e "phpmyadmin\t${PMA_VERSION}" >> version.txt 2>&1

echo "================moodle Install==============="
rm -rf $WEBROOT/moodle
mkdir -p /data
mkdir -p /data/moodledata
chown www:www /data/moodledata
chmod 775 /data/moodledata
if [ "$M_VERSION" = "1" ]; then
     echo "---------- moodle2.6 ----------"
      cd $LANMMP_PATH/
 if [ ! -s moolde-*-26.tgz ]; then
   LATEST_moodle_LINK="http://download.moodle.org/download.php/stable26/moodle-latest-26.tgz"
   BACKUP_moodle_LINK="http://www.hnsssy.com/download/moodle/moodle-latest-26.tgz"
   Extract ${LATEST_moodle_LINK} ${BACKUP_moodle_LINK}
   mkdir -p $WEBROOT/moodle
   mv * $WEBROOT/moodle
 else
   tar -zxf moodle-*-26.tgz -C $WEBROOT
 fi
fi
if [ "$M_VERSION" = "2" ]; then
     echo "---------- moodle2.7 ----------"
     cd $LANMMP_PATH/
    if [ ! -s moolde-*-27.tgz ]; then
       LATEST_moodle_LINK="http://download.moodle.org/download.php/stable27/moodle-latest-27.tgz"
       BACKUP_moodle_LINK="http://www.hnsssy.com/download/moodle/moodle-latest-27.tgz"
       Extract ${LATEST_moodle_LINK} ${BACKUP_moodle_LINK}
       mkdir -p $WEBROOT/moodle
       mv * $WEBROOT/moodle
    else
      tar -zxf moodle-*-27.tgz -C $WEBROOT
    fi
fi
chown www:www $WEBROOT/moodle
chmod 775 $WEBROOT/moodle


cd $LANMMP_PATH/
if [ ! -d "src/" ];then
mkdir -p src
fi
mv ./{*gz,*-*/,*patch,ioncube,package.xml} ./src >/dev/null 2>&1

clear
echo ""
echo "===================== Install completed ====================="
echo ""
echo "LANMMP install completed!"
echo "For more information please visit"
echo ""
echo "Server ip address: $IP_ADDRESS"
echo "MySQL root password: $MYSQL_ROOT_PWD"
echo "MySQL pma password: $PMAPWD"
echo ""
echo "php config file at: /usr/local/php/lib/php.ini"
echo "Pear config file at: /usr/local/php/etc/pear.conf"
[ "$SOFTWARE" = "1" ] && echo "php-fpm config file at: /usr/local/php/etc/php-fpm.conf"
[ "$SOFTWARE" != "2" ] && echo "nginx config file at: /usr/local/nginx/conf/nginx.conf"
[ "$SOFTWARE" != "1" ] && echo "httpd config file at: /usr/local/apache/conf/httpd.conf"
echo ""
echo "WWW root dir: $WEBROOT"
echo "PHP prober: http://$IP_ADDRESS/p.php"
echo "phpMyAdmin: http://$IP_ADDRESS/phpmyadmin/"
echo "moodle: http://$IP_ADDRESS/moodle/"
echo ""
echo "============================================================="
echo ""
