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
    mod_unified_remix \
    manifest-edit \
    python3 \
    python3-pip \
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
# to behave correctly:
#
# --- a/libcrypto.so.1.0.2k.s
# +++ b/libcrypto.so.1.0.2k.s
# @@ -1496,9 +1496,9 @@
#  000000000006e4f0 <CRYPTO_THREADID_set_callback>:
#     6e4f0: 61 0d 00 b0  	adrp	x1, 0x21b000 <CRYPTO_get_dynlock_value+0x40>
#     6e4f4: 21 00 2d 91  	add	x1, x1, #2880
#     6e4f8: 22 18 40 f9  	ldr	x2, [x1, #48]
# -   6e4fc: 62 00 00 b4  	cbz	x2, 0x6e508 <CRYPTO_THREADID_set_callback+0x18>
# +   6e4fc: 03 00 00 14  	b	0x6e508 <CRYPTO_THREADID_set_callback+0x18>
#     6e500: 00 00 80 52  	mov	w0, #0
#     6e504: c0 03 5f d6  	ret
#     6e508: 20 18 00 f9  	str	x0, [x1, #48]
#     6e50c: 20 00 80 52  	mov	w0, #1
RUN sed -e \
    's/\x22\x18\x40\xf9\x62\x00\x00\xb4\x00\x00\x80\x52\xc0\x03\x5f\xd6/\x22\x18\x40\xf9\x03\x00\x00\x14\x00\x00\x80\x52\xc0\x03\x5f\xd6/' \
    /usr/lib64/libcrypto.so.1.0.2k > /usr/lib64/libcrypto.so.1.0.2k.tmp \
 && mv -f /usr/lib64/libcrypto.so.1.0.2k.tmp /usr/lib64/libcrypto.so.1.0.2k \
 && ldconfig

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["-D", "FOREGROUND"]
