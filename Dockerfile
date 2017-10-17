# http://wiki.mayor.hu/doku.php?id=hogyan:telepites#operacios_rendszer_telepitese
FROM debian:jessie

# http://wiki.mayor.hu/doku.php?id=hogyan:telepites-debian#a_etc_apt_sourceslist_kiegeszitese
# Not neccessary for Ubuntu
RUN sed -i 's/deb \([^ ][^ ]*\) \([^ ][^ ]*\) main/deb \1 \2 main contrib non-free/g' /etc/apt/sources.list

# http://wiki.mayor.hu/doku.php?id=hogyan:telepites-man#az_elso_inditas_utan
RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		apache2 \
		php5 php5-mysql php5-ldap \
		mysql-server \
		recode \
		texlive texlive-plain-extra texlive-fonts-extra texlive-fonts-recommended texlive-lang-hungarian texlive-latex-extra cm-super \
		texlive-xetex ttf-mscorefonts-installer \
		ghostscript \
		ntp \
		wget \
		ssl-cert \
		ssh \
	&& rm -r /var/lib/apt/lists/*

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		pwgen \
		supervisor \
	&& rm -r /var/lib/apt/lists/*

CMD ["/usr/bin/supervisord"]
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
EXPOSE 80


# http://wiki.mayor.hu/doku.php?id=hogyan:telepites-man#mayor_rendszer_telepitese

# php_memory_limit: Increasing memory limit just to make sure if our scripts are succeeding
ARG php_memory_limit=256M
RUN sed -i "s/memory_limit/memory_limit = $php_memory_limit ; old value: /" /etc/php5/apache2/php.ini
ADD virtualhost.conf /etc/apache2/sites-available/mayor.conf
RUN a2dissite 000-default && a2ensite mayor
#RUN service apache2 reload

ENV TMPDIR="/tmp"

# VERSION: MaYoR version to download and install
ARG VERSION="current"
RUN mkdir -p "$TMPDIR" \
	&& wget "http://www.mayor.hu/download/current/mayor-base-$VERSION.tgz" -O "$TMPDIR/mayor-base.tgz" \
	&& wget "http://www.mayor.hu/download/current/mayor-naplo-$VERSION.tgz" -O "$TMPDIR/mayor-naplo.tgz"
# PREFIX: Install "directory"...
ARG PREFIX="/var"
# INSTALLDIR: Directory to target in `PREFIX`
ARG INSTALLDIR="mayor"
ENV MAYORDIR="$PREFIX/$INSTALLDIR"
RUN mkdir -p "$MAYORDIR" \
	&& tar -xzf "$TMPDIR/mayor-base.tgz" -C "$MAYORDIR" \
	&& tar -xzf "$TMPDIR/mayor-naplo.tgz" -C "$MAYORDIR" \
	&& rm "$TMPDIR/mayor-base.tgz" "$TMPDIR/mayor-naplo.tgz"

RUN sed -i "s#/var/mayor#$MAYORDIR#g" /etc/apache2/sites-available/mayor.conf
#RUN service apache2 reload

RUN cp "$MAYORDIR/install/base/mysql/utf8.cnf" /etc/mysql/conf.d/utf8.cnf
#RUN service mysql restart

# http://wiki.mayor.hu/doku.php?id=hogyan:telepites-man#karbantartast_segito_szkriptek
RUN ln -s "$MAYORDIR/bin/mayor" "/usr/local/sbin"
RUN ln -s "$MAYORDIR/bin/etc/cron.daily/mayor" "/etc/cron.daily"
RUN cp "$MAYORDIR/config/main.conf.example" "$MAYORDIR/config/main.conf"
RUN chown -R "$(bash -c 'source /etc/apache2/envvars && echo $APACHE_RUN_GROUP')" "$MAYORDIR/config/" \
	&& chmod 700 "$MAYORDIR/config/" \
	&& chown root "$MAYORDIR/config/main.conf" \
	&& chmod 600 "$MAYORDIR/config/main.conf"

# http://wiki.mayor.hu/doku.php?id=hogyan:telepites-man#szimbolikus_linkek_es_jogosultsagok
RUN if [ -e "$MAYORDIR/download" ]; then \
		chown -R "$(bash -c 'source /etc/apache2/envvars && echo $APACHE_RUN_GROUP')" "$MAYORDIR/download"; \
	fi && if [ -e "$MAYORDIR/www/wiki/conf" ]; then \
		chown -R "$(bash -c 'source /etc/apache2/envvars && echo $APACHE_RUN_GROUP')" "$MAYORDIR/www/wiki/conf"; \
	fi && if [ -e "$MAYORDIR/www/wiki/data" ]; then \
		chown -R "$(bash -c 'source /etc/apache2/envvars && echo $APACHE_RUN_GROUP')" "$MAYORDIR/www/wiki/data"; \
	fi
ADD linker.sh linker.sh
RUN ./linker.sh && rm ./linker.sh

# Create mayor.fmt according to install.d/55tex.sh from http://www.mayor.hu/download/current/mayor-installer-rev4208.tgz
RUN ( \
	cd "$MAYORDIR/print/module-naplo/tex/" \
	&& fmtutil-sys --cnffile "$MAYORDIR/print/module-naplo/tex/mayor.cnf" --fmtdir "$MAYORDIR/print/module-naplo/" --byfmt mayor \
	&& if [ -e "$MAYORDIR/print/module-naplo/mayor.fmt" ]; then mv "$MAYORDIR/print/module-naplo/mayor.fmt" "$MAYORDIR/print/module-naplo/tex/mayor.fmt"; fi \
) && ( \
	cd "$MAYORDIR/print/module-naplo/xetex/" \
	&& fmtutil-sys --cnffile "$MAYORDIR/print/module-naplo/xetex/mayor-xetex.cnf" --fmtdir "$MAYORDIR/print/module-naplo/" --byfmt mayor-xetex \
)

# Modified install.d/15createconfig.sh from http://www.mayor.hu/download/current/mayor-installer-rev4208.tgz
ADD createconfig.sh createconfig.sh
RUN ./createconfig.sh && rm createconfig.sh

# Improved http://wiki.mayor.hu/doku.php?id=hogyan:telepites-man#mysql_beallitasa
ADD createsqls.sh createsqls.sh
RUN ./createsqls.sh && rm createsqls.sh
# MYSQL_ROOT_PASSWORD: Set up this pw for mysql root user (to be ENVed)
ARG MYSQL_ROOT_PASSWORD
ENV MYSQLROOTPW="${MYSQL_ROOT_PASSWORD:-root}"
RUN service mysql start \
	&& mysqladmin -u root password "$MYSQLROOTPW" \
	&& service mysql stop
ADD importsql.sh importsql.sh
RUN ./importsql.sh \
	"$TMPDIR/mysql/mayor-login.sql" \
	"$TMPDIR/mysql/mayor-parent.sql" \
	"$TMPDIR/mysql/mayor-private.sql" \
	"$TMPDIR/mysql/base.sql" \
	"$TMPDIR/mysql/private-users.sql" \
	"$TMPDIR/mysql/naplo-users.sql" \
	&& rm importsql.sh

# HOSTNAME: System public domain name
ARG HOSTNAME

# http://wiki.mayor.hu/doku.php?id=hogyan:telepites-man#az_apache_web-szerver_beallitasai
RUN a2enmod ssl \
	&& mkdir /etc/apache2/ssl \
	&& (echo "${HOSTNAME:-localhost}"; echo "") | make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /etc/apache2/ssl/apache.pem \
	&& sed -i -e 's/\*:80/\*:443/' -e 's/#\(SSL.*\)/\1/' /etc/apache2/sites-available/mayor.conf
EXPOSE 443
RUN a2enmod rewrite \
	&& a2ensite 000-default \
	&& sed -i '/<\/VirtualHost>/i\
\	RewriteEngine On\n\
\	RewriteRule (.*)$ https://%{SERVER_NAME}/$1 [L]' \
/etc/apache2/sites-available/000-default.conf

RUN sed -i -e "s/#\?\(ServerName \).*/\1$HOSTNAME/" /etc/apache2/sites-available/mayor.conf
RUN sed -i -e "s/#\?\(ServerName \).*/\1$HOSTNAME/" /etc/apache2/sites-available/mayor.conf \
	&& echo "ServerName $HOSTNAME" >>/etc/apache2/apache2.conf
