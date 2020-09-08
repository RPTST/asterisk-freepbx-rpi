FROM arm32v7/node:12-stretch

ENV DEBIAN_FRONTEND noninteractive

### prepare for php 5.6
RUN apt-get update  && apt-get install -y ca-certificates apt-transport-https && \
              wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - && \
              echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list

### Install runtime depencies
RUN apt-get update  && apt-get install --no-install-recommends -y \
              autoconf automake bison build-essential doxygen flex libasound2-dev libcurl4-openssl-dev \
              libedit-dev libical-dev libiksemel-dev libjansson-dev libmariadbclient-dev libncurses5-dev libneon27-dev \
              libnewt-dev libogg-dev libresample1-dev libspandsp-dev libsqlite3-dev libsrtp0-dev libssl-dev libtiff-dev \
              libtool-bin libvorbis-dev libxml2-dev pkg-config python-dev subversion unixodbc-dev uuid-dev \
              apache2 composer fail2ban flite ffmpeg git g++ iproute2 iptables lame libiodbc2 libicu-dev libsrtp0 locales-all \
              mariadb-client mariadb-server mpg123 net-tools php5.6 php5.6-cli php5.6-curl php5.6-gd php5.6-ldap php5.6-mbstring \
              php5.6-mysql php5.6-sqlite php5.6-xml php5.6-zip php-pear procps sox sqlite3 sudo unixodbc uuid vim wget whois xmlstarlet \
	cron aptitude \
	&& rm -rf /var/lib/apt/lists/*

### Install Legacy MySQL Connector
RUN printf "Package: *\nPin: release n=stretch\nPin-Priority: 900\nPackage: *\nPin: release n=jessie\nPin-Priority: 100" >> /etc/apt/preferences.d/jessie \
	&& echo "deb http://mirrordirector.raspbian.org/raspbian/ jessie main contrib" >> /etc/apt/sources.list \
	&& curl -s http://archive.raspbian.org/raspbian.public.key | apt-key add - \
	&& apt-get update \
	&& apt-get -y --allow-unauthenticated install libmyodbc \
	&& sed '$d' /etc/apt/sources.list \
	&& rm /etc/apt/preferences.d/jessie

### Build SpanDSP
RUN mkdir /TEMP \
	&& cd /TEMP
#COPY ./config/libspandsp2_0.0.6-2.1_armhf.deb /TEMP/libspandsp2_0.0.6-2.1_armhf.deb
#RUN  dpkg -i libspandsp2_0.0.6-2.1_armhf.deb || true
COPY ./config/gdrive_download.sh gdrive_download.sh
RUN chmod +x gdrive_download.sh \
	&& ./gdrive_download.sh \
	&& dpkg -i libspandsp2_0.0.6-2.1_armhf.deb || true

### Build Asterisk 15.7.2
#RUN cd /usr/src \
#	&& wget https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-15.7.1.tar.gz \
RUN cd /TEMP/
COPY ./config/gdrive_asterisk.sh gdrive_asterisk.sh
RUN chmod +x gdrive_asterisk.sh \
        && ./gdrive_asterisk.sh \
	&& mv asterisk-15.7.2.tar.gz /usr/src/asterisk-15.7.2.tar.gz \
	&& cd /usr/src \
	&& tar xfz asterisk-15.7.2.tar.gz \
	&& cd asterisk-* \
	&& contrib/scripts/get_mp3_source.sh \
	&& ./configure --with-resample --with-pjproject-bundled --with-jansson-bundled --with-ssl=ssl --with-srtp \
	&& make menuselect/menuselect menuselect-tree menuselect.makeopts \
	&& menuselect/menuselect --disable BUILD_NATIVE --enable app_confbridge --enable app_fax \
                             --enable app_macro --enable format_mp3 \
                             --enable BETTER_BACKTRACES --disable MOH-OPSOUND-WAV --enable MOH-OPSOUND-GSM \
	&& make \
	&& make install \
	&& make samples \
	&& make config \
	&& ldconfig \
	&& update-rc.d -f asterisk remove \
	&& rm -r /usr/src/asterisk*

### Add users
RUN useradd -m asterisk \
	&& chown asterisk. /var/run/asterisk \
	&& chown -R asterisk. /etc/asterisk \
	&& chown -R asterisk. /var/lib/asterisk \
	&& chown -R asterisk. /var/log/asterisk \
	&& chown -R asterisk. /var/spool/asterisk \
	&& chown -R asterisk. /usr/lib/asterisk \
	&& rm -rf /var/www/html

### Optimize PHP5.6
RUN sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 120M/' /etc/php/5.6/apache2/php.ini \
	&& sed -i 's/^memory_limit = 128M/memory_limit = 256M/' /etc/php/5.6/apache2/php.ini \
	&& cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig \
	&& sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf \
	&& sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

### Setup ODBC
COPY ./config/odbcinst.ini /etc/odbcinst.ini
COPY ./config/odbc.ini /etc/odbc.ini

### Install FreePBX 14.0 latest
#RUN cd /usr/src \
#	&& wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz \
RUN cd /TEMP/
COPY ./config/gdrive_freepbx.sh gdrive_freepbx.sh
RUN chmod +x gdrive_freepbx.sh \
        && ./gdrive_freepbx.sh \
	&& mv freepbx-14.0-latest.tgz /usr/src/freepbx-14.0-latest.tgz \
	&& cd /usr/src \
	&& tar xfz freepbx-14.0-latest.tgz \
	&& cd freepbx \
	&& chown mysql:mysql -R /var/lib/mysql/* \
	&& /etc/init.d/mysql start \
	&& ./start_asterisk start \
	&& ./install -n \
	&& fwconsole chown \
	&& fwconsole ma upgradeall \
	&& fwconsole ma downloadinstall announcement backup bulkhandler ringgroups ivr cel calendar timeconditions \
	&& fwconsole ma downloadinstall soundlang recordings voicemail sipsettings infoservices featurecodeadmin logfiles conferences callrecording dashboard music \
	&& fwconsole ma downloadinstall certman userman restapi pm2 \
# ucp-fix : https://community.freepbx.org/t/ucp-upgrade-error/58273/4
	&& touch /usr/bin/icu-config \
	&& echo "icuinfo 2>/dev/null|grep '\"version\"'|sed 's/.*\">\(.*\)<.*/\\\1/g'" > /usr/bin/icu-config \
	&& chmod +x /usr/bin/icu-config \
	&& fwconsole ma downloadinstall ucp \
	&& /etc/init.d/mysql stop \
	&& rm -rf /usr/src/freepbx*

RUN a2enmod rewrite

### Add G729 Codecs 1.0.4 for Asterisk 15
RUN	cd /usr/src \
	&& git clone https://github.com/RPTST/bcg729.git \
	&& cd bcg729 \
	&& git checkout tags/1.0.4 \
	&& ./autogen.sh \
	&& ./configure --libdir=/lib \
	&& make \
	&& make install \
	&& mkdir -p /usr/src/asterisk-g72x \
	&& cd /usr/src \
	&& git clone https://github.com/RPTST/asterisk-g72x.git \
#	&& curl https://bitbucket.org/arkadi/asterisk-g72x/get/default.tar.gz | tar xvfz - --strip 1 -C /usr/src/asterisk-g72x \
#	&& rm -f asterisk-g72x-1.4.3.tar.bz2 \
	&& cd asterisk-g72x \
	&& ./autogen.sh  \
	&& ./configure CFLAGS='-march=armv7' --with-bcg729 --with-asterisk150 --enable-penryn \
	&& make \
	&& make install

RUN sed -i 's/^user		= mysql/user		= root/' /etc/mysql/my.cnf

### Cleanup 
RUN mkdir -p /var/run/fail2ban && \
             cd / && \
             rm -rf /usr/src/* /tmp/* /etc/cron* && \
             apt --fix-broken install -y && \
             apt-get purge -y autoconf automake bison build-essential doxygen flex libasound2-dev libcurl4-openssl-dev \
             libedit-dev libical-dev libiksemel-dev libjansson-dev libmariadbclient-dev libncurses5-dev libneon27-dev \
             libnewt-dev libogg-dev libresample1-dev libspandsp-dev libsqlite3-dev libsrtp0-dev libssl-dev libtiff-dev \
             libtool-bin libvorbis-dev libxml2-dev pkg-config python-dev subversion unixodbc-dev uuid-dev libspandsp-dev && \
             apt-get -y autoremove && \
             apt-get clean && \
             apt-get install -y make && \
             rm -rf /var/lib/apt/lists/*

COPY ./run /run
RUN chmod +x /run/*

RUN chown asterisk:asterisk -R /var/spool/asterisk

CMD /run/startup.sh

EXPOSE 80 3306 5060 5061 5160 5161 4569 10000-20000/udp

#recordings data
VOLUME [ "/var/spool/asterisk/monitor" ]
#database data
VOLUME [ "/var/lib/mysql" ]
#automatic backup
VOLUME [ "/backup" ]
