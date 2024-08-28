FROM webdevops/php-nginx:8.2

# install required packages
RUN curl -s https://deb.nodesource.com/setup_18.x | bash
RUN apt-get update
RUN apt-get install libaio1 libaio-dev nodejs

# install oracle instantclient
RUN mkdir -p /opt/oracle && \
    cd /opt/oracle && \
    wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-19.6.0.0.0dbru.zip && \
    unzip instantclient-sdk-linux.x64-19.6.0.0.0dbru.zip && \
    rm -f *.zip && \
    ln -s /opt/oracle/instantclient_19_6 /opt/oracle/instantclient && \
    ln -s /opt/oracle/instantclient/libclntsh.so.19.1 /usr/lib/libclntsh.so

ENV LD_LIBRARY_PATH /opt/oracle/instantclient

RUN echo 'instantclient,/opt/oracle/instantclient' | pecl install oci8-3.3.0
RUN docker-php-ext-enable oci8
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Set TNS_ADMIN environment variable
ENV ORACLE_HOME=/opt/oracle/instantclient
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient
ENV OCI_LIB_DIR=/opt/oracle/instantclient
ENV OCI_INC_DIR=/opt/oracle/instantclient/sdk/include
ENV TNS_ADMIN /opt/oracle/instantclient/network/admin

WORKDIR /app

COPY --chown=application:application . .

# coppy wallet file to TNS_ADMIN directory
COPY ./wallet/tnsnames.ora $TNS_ADMIN
COPY ./wallet/sqlnet.ora $TNS_ADMIN
COPY ./wallet/cwallet.sso $TNS_ADMIN
COPY ./nginx/conf.d/ /opt/docker/etc/nginx/vhost.common.d/
COPY ./nginx/ssl/ /opt/docker/etc/nginx/ssl/

# install laravel dependencies
RUN composer update && composer install

# install and build frontend
RUN npm install && \
    npm run build
