################################################
# auhtor mengwei longfeiyiying@gmail.com
# modify 2015-01-04  9:06:22 UTC
################################################
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
wget=`which wget`
gawk=`which awk`
tar=`which tar`
pwd=`pwd`
#系统类型debian centos
ostype=`sed '/^$/d' /etc/issue | awk '{print $1}'`
sf='wget.txt'
delimiter=','
# 服务安装目录
prefix="/www"
# 文档目录
htdoces=${prefix}/htdocs
isd=0
isz=0
#########################################
#下载信息文件 
downfile() {
	[ -f "$sf" ] || cat >$sf<<EOF 
############################################################
# 软件名称,是否下载,是否解压,下载地址
############################################################
libxml2${delimiter}${isd}${delimiter}${isz}${delimiter}http://downloads.openwrt.org/sources/libxml2-2.7.8.tar.gz
libmcrypt${delimiter}${isd}${delimiter}${isz}${delimiter}http://downloads.openwrt.org/sources/libmcrypt-2.5.7.tar.gz
zlib${delimiter}${isd}${delimiter}${isz}${delimiter}http://downloads.openwrt.org/sources/zlib-1.2.7.tar.bz2
libpng${delimiter}${isd}${delimiter}${isz}${delimiter}http://downloads.openwrt.org/sources/libpng-1.2.46.tar.bz2
jpegsrc${delimiter}${isd}${delimiter}${isz}${delimiter}http://downloads.openwrt.org/sources/jpegsrc.v6b.tar.gz
freetype${delimiter}${isd}${delimiter}${isz}${delimiter}http://downloads.openwrt.org/sources/freetype-2.4.8.tar.bz2
autoconf${delimiter}${isd}${delimiter}${isz}${delimiter}http://downloads.openwrt.org/sources/autoconf-2.68.tar.bz2
gd2${delimiter}${isd}${delimiter}${isz}${delimiter}http://distfiles.macports.org/gd2/gd-2.0.35.tar.bz2
httpd${delimiter}${isd}${delimiter}${isz}${delimiter}http://mirrors.cnnic.cn/apache/httpd/httpd-2.2.29.tar.bz2
ncurses${delimiter}${isd}${delimiter}${isz}${delimiter}http://mirror.bjtu.edu.cn/gnu/ncurses/ncurses-5.9.tar.gz
#mysql${delimiter}${isd}${delimiter}${isz}${delimiter}http://mirrors.sohu.com/mysql/MySQL-5.5/mysql-5.5.44-linux2.6-i686.tar.gz
php${delimiter}${isd}${delimiter}${isz}${delimiter}http://mirrors.sohu.com/php/php-5.3.28.tar.bz2
#ZendOptimizer${delimiter}${isd}${delimiter}${isz}${delimiter}http://down1.chinaunix.net/distfiles/ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz
phpMyAdmin${delimiter}${isd}${delimiter}${isz}${delimiter}http://nchc.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/4.4.3/phpMyAdmin-4.4.3-all-languages.zip
#vsftpd${delimiter}${isd}${delimiter}${isz}${delimiter}http://pkgs.fedoraproject.org/repo/pkgs/vsftpd/vsftpd-3.0.2.tar.gz/8b00c749719089401315bd3c44dddbb2/vsftpd-3.0.2.tar.gz
EOF
}
#检查系统是否必要库
pre() {
    case $ostype in
        "Debian")
            libs='gcc g++ make db4.8-util libssl-dev libaio-dev chkconfig'
            for lib in $libs
            do
                l=`dpkg -l|awk '{print $2}'|grep ^${lib}$`
                if [ -z "$l" ]; then
                    aptitude -y install $lib
                fi
            done
            ;;
        "Centos")
            yum -y install gcc gcc-c++ make openssl-devel
            ;;
    esac
}
#检测系统帐号是否存在
isUser(){
	local author=$1
	local group=`grep ^$author: /etc/group`
	local user=`grep ^$author: /etc/passwd`
	[[ $group =~ ^$author ]] || groupadd $author
	if [[ $MACHTYPE =~ "redhat" ]]; then 
		[[ $user =~ ^$author ]] || useradd -M -s /sbin/nologin -g $author $author	
	else
		[[ $user =~ ^$author ]] || useradd -M -s /bin/false -g $author $author
	fi
}
# 初始化
initc() {
	local sinfo=$1
	# 下载目录
	dDir='Downloads'
	# 解压缩目录
	dsrc='src'
	# 获取字段软件名称和软件下载地址
	sname=`echo $sinfo|grep -v '#'|cut -d$delimiter -f1`
	[ -z $sname ] && continue
	isdown=`echo $sinfo|grep -v '#'|cut -d$delimiter -f2`
	isz=`echo $sinfo|grep -v '#'|cut -d$delimiter -f3`
	saddr=`echo $sinfo|grep -v '#'|cut -d$delimiter -f4`
	fsname=`basename $saddr`
	# 没有下载目录就建立目录 
    [ -d $dDir ] || mkdir "$dDir"
    [ -d $htdoces ] || mkdir "$htdoces"
	[ -d $dsrc ] || mkdir "$dsrc"
	if [ -n "$sname" ]; then
		if [ -f "${dDir}/${fsname}" ] && [ $isdown -eq 1 ]; then
			z 
		else	
			rm -f "${dDir}/${fsname}" 2>/dev/null
			download 
		fi
	fi
}
# 下载源码包
download() {
	echo "start downing..."
	echo "$sname Package"
	$wget -P$dDir $saddr
	if [ $? = 0 ]; then
		echo  "download finish"
		`rm -f wget-log*`
		`sed -i /$sname/s/0/1/1 $sf`
		z 
	else
		echo  "$sname download error"
		`rm -f "${dDir}/${fsname}"`
	fi
}
# 解压缩源码包
z() {
	local suffix=`echo "$fsname" | $gawk -F'.' '{print $NF}'`
	z_dir=`echo "$fsname" |sed 's/\.tar.*$//g'`
	case $suffix in
		"bz2")
			local opt="xjf"
			;;
		"xz")
			local opt="xJf"
			;;
		"gz")
			local opt="xzf"
			;;
		"zip")
			local opt="zf"
			z_dir=`basename $fsname ".${suffix}"`
			;;
	esac
	[ $isz -eq 1 ] && continue 
	echo "extract $fsname..."
	if [ $opt == "zf" ]; then
		unzip "${dDir}/${fsname}" -d "${dsrc}/"
	else
		$tar $opt "${dDir}/${fsname}" -C "${dsrc}/"
	fi
	if [ $? -eq 0 ]; then
		echo "OK" 
		`sed -i /$sname/s/0/1/1 $sf`
		doing 
	else 
		echo "error" 
		rm -f "${dDir}/${fsname}"
	fi
}
# 编译安装
doing () {
    if [ $sname = 'jpegsrc' ]; then
        mkdir $prefix/libs/jpeg6
        mkdir $prefix/libs/jpeg6/bin
        mkdir $prefix/libs/jpeg6/lib
        mkdir $prefix/libs/jpeg6/include
        mkdir -p $prefix/libs/jpeg6/man/man1
        cd "${dsrc}/jpeg-6b"
    #elif [ $sname = 'gd2' ]; then
     #   cd "${dsrc}/${z_dir}"
    else
	 cd "${dsrc}/${z_dir}"
    fi
	case $sname in 
		"httpd")
            ./configure --prefix=$prefix/apache2/ --sysconfdir=$prefix/apache2/etc/ --with-included-apr --disable-userdir --enable-so --enable-deflate=shared --enable-expires=shared --enable-rewrite=shared --enable-static-support
            make && make install
            $prefix/apache2/bin/apachectl start
            echo "${prefix}/apache2/bin/apachectl start" >> /etc/rc.local
			;;
		"mysql") 
            local mysql_prefix="$prefix/$sname"
            isUser $sname
            cd ../
            mv ${z_dir} $mysql_prefix
            cd $mysql_prefix
            cp support-files/my-medium.cnf /etc/my.cnf
            sed -i '/\[client\]/a default-character-set=utf8' /etc/my.cnf
            sed -i "/\[mysqld\]/a basedir = $mysql_prefix\ndatadir = $mysql_prefix/data\ncharacter-set-server=utf8\ncollation-server=uf8_general_ci" /etc/my.cnf
            
            $mysql_prefix/scripts/mysql_install_db --user=mysql
            chown -R root $mysql_prefix
            chown -R mysql $mysql_prefix/data
            chgrp -R mysql $mysql_prefix
            cp support-files/mysql.server /etc/init.d/mysqld
            chown root.root /etc/init.d/mysqld
            chmod 755 /etc/init.d/mysqld
            chkconfig --add mysqld
			;;
		"php")
            ./configure --prefix=$prefix/php --with-config-file-path=$prefix/php/etc --with-apxs2=$prefix/apache2/bin/apxs --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-libxml-dir=$prefix/libs/libxml2 --with-gd=$prefix/libs/gd2 --with-png-dir=$prefix/libs/libpng --with-jpeg-dir=$prefix/libs/jpeg6 --with-freetype-dir=$prefix/libs/freetype  --with-mcrypt=$prefix/libs/libmcrypt --enable-soap --enable-mbstring --enable-sockets
            make && make install
            cp php.ini-production $prefix/php/etc/php.ini
            sed -i '/^\#ServerName/a ServerName 127.0.0.1:80' $prefix/apache2/etc/httpd.conf
            sed -i 's/\(DirectoryIndex\)/\1 index.php/' /$prefix/apache2/etc/httpd.conf
            sed -i 's#\(^DocumentRoot\).*#\1 "/www/htdocs"#' $prefix/apache2/etc/httpd.conf
            sed -i 's#^<Directory \"/www/apache2//htdocs\">#<Directory "/www/htdocs">#' $prefix/apache2/etc/httpd.conf
            echo "Addtype application/x-httpd-php .php .phtml html" >> $prefix/apache2/etc/httpd.conf
            $prefix/apache2/bin/apachectl -k restart
			;;
		"phpMyAdmin")
            cd ../
            mv  ${z_dir} $htdoces/$sname
            cp  $htdoces/$sname/config.sample.inc.php $htdoces/$sname/config.inc.php
            sed -i "s#'cookie'#'http'#" $htdoces/$sname/config.inc.php
			;;
		"libxml2")
            ./configure --prefix=${prefix}/libs/${sname}
            make && make install
			;;
		"libmcrypt")
            ./configure --prefix=$prefix/libs/$sname
            make && make install
            cd libltdl/
            ./configure -enable-ltdl-install
            make && make install 
			;;
		"zlib")
            ./configure
            make && make install
			;;
		"gd2")
            `sed -i "s#\"png.h\"#\"$prefix/libs/libpng/include/png.h\"#1" gd_png.c`
            ./configure --prefix=$prefix/libs/${sname}  --with-jpeg=$prefix/libs/jpeg6/ --with-png=$prefix/libs/libpng/ --with-freetype=$prefix/libs/freetype/
            make && make install
			;;
		"autoconf")
            ./configure
            make && make install
			;;
		"libpng")
            ./configure --prefix=$prefix/libs/$sname
            make && make install
			;;
		"freetype")
            if [ -f $prefix/libs/$sname ]; then
                mkdir -p "$prefix/libs/$sname"
            fi
            ./configure --prefix=$prefix/libs/$sname
            make && make install
			;;
		"jpegsrc")
            ./configure --prefix=$prefix/libs/jpeg6 -enable-shared -enable-static
            make && make install
			;;
		"ncurses")
            ./configure --with-shared --without-debug --without-ada --enable-overwrite
            make && make install
			;;
		"ZendOptimizer")
            cp data/5_2_x_comp/ZendOptimizer.so $prefix/php/
            echo "zend_extension=ZendOptimizer.so" >> $prefix/php/etc/php.ini
            ;;
		"vsftpd")
            install_vsftpd
			;;
	esac
	cd $pwd 
}
#1
pre
#2
downfile
#3
# 主体循环读取文件
while read var
do
    initc $var
done <<EOF
`cat ${sf}`
EOF
    


