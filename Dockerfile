FROM arm64v8/amazonlinux

RUN echo $'[unified-streaming] \n\
name=unified-streaming \n\
baseurl=http://artifact.internal.unified-streaming.com/latest/artifact/yum/amzn2/aarch64 \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://stable.yum.unified-streaming.com/unifiedstreaming.pub' > /etc/yum.repos.d/unified-streaming.repo

# Install Origin
RUN yum install -y systemd httpd mod_ssl openssl \
    mp4split \
    mod_smooth_streaming \
    mod_unified_s3_auth

# Set up directories and log file redirection
RUN mkdir -p /run/httpd \
    && ln -s /dev/stderr /var/log/httpd/error_log \
    && ln -s /dev/stdout /var/log/httpd/access_log \
    && ln -s /dev/stderr /var/log/httpd/ssl_error_log \
    && ln -s /dev/stdout /var/log/httpd/ssl_access_log \
    && mkdir -p /var/www/unified-origin

#RUN rm /etc/httpd/conf.d/ssl.conf
#RUN mv /etc/httpd/conf.modules.d/00-ssl.conf /etc/httpd/conf.modules.d/16-ssl.conf

COPY httpd.conf /etc/httpd/httpd.conf
#COPY ssl.conf /etc/httpd/conf.d/000-ssl.conf
COPY unified-origin.conf.in /etc/httpd/conf.d/unified-origin.conf.in
COPY s3_auth.conf.in /etc/httpd/conf.d/s3_auth.conf.in
COPY remote_storage.conf.in /etc/httpd/conf.d/remote_storage.conf.in
COPY transcode.conf.in /etc/httpd/conf.d/transcode.conf.in
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY index.html /var/www/unified-origin/index.html
COPY clientaccesspolicy.xml /var/www/unified-origin/clientaccesspolicy.xml
COPY crossdomain.xml /var/www/unified-origin/crossdomain.xml
COPY make-dummy-cert.tgz /etc/pki/tls/certs/make-dummy-cert.tgz

#RUN cd /etc/pki/tls/certs/ && tar -zxvf make-dummy-cert.tgz && ./make-dummy-cert localhost.crt
#RUN cd /etc/pki/tls/certs/ && \
#openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/localhost.key -out /etc/ssl/certs/localhost.crt
RUN cd /etc/pki/tls/ && \
openssl req  -nodes -new -x509  -keyout private/localhost.key -out certs/localhost.crt -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"

RUN mv /etc/httpd/conf.modules.d/00-ssl.conf /etc/httpd/conf.modules.d/000-ssl.conf

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["-D", "FOREGROUND"]
