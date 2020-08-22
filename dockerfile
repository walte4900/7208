FROM ubuntu:18.04

LABEL MAINTAINER = "Ziwen Wang <ziwen.wang1@uqconnect.edu.au>"
LABEL PHPVERSION = "7.4"

ENV PHPVER=7.4
ENV DEBIAN_FRONTEND noninteractive

#Install dependencies and libraries
RUN apt-get update  

RUN apt-get install --no-install-recommends --no-install-suggests -qq -y \
	curl gcc make autoconf libc-dev zlib1g-dev pkg-config apt-utils \
	gnupg2 dirmngr wget \
	apt-transport-https lsb-release ca-certificates \
	software-properties-common

RUN rm -rf /var/lib/apt/list/*

#Install Nginx,PHP,PHP-FPM
RUN add-apt-repository ppa:ondrej/php && apt-get update 
RUN apt-get install --no-install-recommends --no-install-suggests -qq -y \
		nginx php${PHPVER} php${PHPVER}-cli php${PHPVER}-fpm php${PHPVER}-json \
		php${PHPVER}-pdo php${PHPVER}-pgsql php${PHPVER}-zip php${PHPVER}-gd php${PHPVER}-mbstring \
		php${PHPVER}-curl php${PHPVER}-xml php${PHPVER}-bcmath php${PHPVER}-json
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

#Install setup PHP-FPM
RUN sed -i -e "s/pid =.*/pid = \/var\/run\/php${PHPVER}-fpm.pid/" \
		/etc/php/${PHPVER}/fpm/php-fpm.conf\
&& sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" \
		/etc/php/${PHPVER}/fpm/php-fpm.conf \
&& sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
		/etc/php/${PHPVER}/fpm/php-fpm.conf \ 
&& sed -i "s/listen =.*/listen = 127.0.0.1:9000/" \
		/etc/php/${PHPVER}/fpm/pool.d/www.conf

#Setup Nginx
RUN rm -rf /etc/nginx/conf.d/default.conf \
&& sed -i -e "s/root=.*/root \/var\/www\/html;/" \
		/etc/nginx/sites-enabled/default \ 
&& sed -i -e "44s/;/ index.php&/" \
		/etc/nginx/sites-enabled/default \
&& sed -i -e "56s/#//" \ 
		/etc/nginx/sites-enabled/default \
&& sed -i -e "57c \\\t\\ttry_files \$uri \$uri\/ \/index.php\?\$query_string;" \
		/etc/nginx/sites-enabled/default \
&& sed -i -e "58c \\\t\\tfastcgi_split_path_info \^(.+\\\.php)(\/.+)\$;" \
		/etc/nginx/sites-enabled/default \
&& sed -i -e "59c \\\t\\tfastcgi_pass 127.0.0.1:9000;" \
		/etc/nginx/sites-enabled/default \
&& sed -i -e "60c \\\t\\tfastcgi_index index.php;" \
		/etc/nginx/sites-enabled/default \
&& sed -i -e "61c \\\t\\tinclude fastcgi_params;" \
		/etc/nginx/sites-enabled/default \
&& sed -i -e "62c \\\t\\tfastcgi_param SCRIPT_FILENAME \/var\/www\/html\$fastcgi_script_name;" \
		/etc/nginx/sites-enabled/default \
&& sed -i -e "62a \\\t\\tfastcgi_param PATH_INFO \$fastcgi_path_info;" \
		/etc/nginx/sites-enabled/default \
&& sed -i -e "64s/#//" \
		/etc/nginx/sites-enabled/default

EXPOSE 80 443


#Run php-fpm and nginx
COPY $PWD/src/. /usr/share/nignx/html
ENTRYPOINT service php${PHPVER}-fpm start && nginx -g "daemon off;"


