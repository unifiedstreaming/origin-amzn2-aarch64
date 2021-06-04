FROM arm64v8/amazonlinux

RUN echo $'[unified-streaming] \n\
name=unified-streaming \n\
baseurl=https://beta.yum.unified-streaming.com/amzn2/aarch64 \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://beta.yum.unified-streaming.com/unifiedstreaming.pub' > /etc/yum.repos.d/unified-streaming.repo

# Install Origin
RUN yum install -y \
    httpd \
    mod_ssl \
    mp4split \
    mod_smooth_streaming \
    mod_unified_s3_auth \
    manifest-edit \
    python3 \
    py3-pip \
&&  pip3 install \
    pyyaml==5.3.1 \
    schema==0.7.3 

# Set up directories and log file redirection
RUN mkdir -p /run/httpd \
    && ln -s /dev/stderr /var/log/httpd/error_log \
    && ln -s /dev/stdout /var/log/httpd/access_log \
    && mkdir -p /var/www/unified-origin

COPY httpd.conf /etc/httpd/httpd.conf
COPY ssl.conf /etc/httpd/conf.d/ssl.conf
COPY unified-origin.conf.in /etc/httpd/conf.d/unified-origin.conf.in
COPY s3_auth.conf.in /etc/httpd/conf.d/s3_auth.conf.in
COPY remote_storage.conf.in /etc/httpd/conf.d/remote_storage.conf.in
COPY transcode.conf.in /etc/httpd/conf.d/transcode.conf.in
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY index.html /var/www/unified-origin/index.html
COPY clientaccesspolicy.xml /var/www/unified-origin/clientaccesspolicy.xml
COPY crossdomain.xml /var/www/unified-origin/crossdomain.xml

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["-D", "FOREGROUND"]

# NOTE: The following workaround is used to mitigate bug https://bz.apache.org/bugzilla/show_bug.cgi?id=60947 by
# Manually patching the CRYPTO_THREADID_set_callback() function in OpenSSL's libcrypto.so, forcing it
# to behave correctly.
RUN sed -e \
    's/\x61\x0d\x00\xb0\x21\xc0\x2c\x91\x22\x18\x40\xf9\x62\x00\x00\xb4\x00\x00\x80\x52\xc0\x03\x5f\xd6/\x61\x0d\x00\xb0\x21\xc0\x2c\x91\x22\x18\x40\xf9\x03\x00\x00\x14\x00\x00\x80\x52\xc0\x03\x5f\xd6/' \
    /usr/lib64/libcrypto.so.1.0.2k > /usr/lib64/libcrypto.so.1.0.2k.tmp \
 && mv -f /usr/lib64/libcrypto.so.1.0.2k.tmp /usr/lib64/libcrypto.so.1.0.2k \
 && ldconfig

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["-D", "FOREGROUND"]
