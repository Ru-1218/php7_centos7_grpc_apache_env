FROM centos:7

# system update
RUN yum -y update && yum clean all

RUN yum -y install sudo
RUN yum install -y vim git which



#http
RUN yum -y install httpd



SHELL ["/bin/bash", "-c"]

# prj create
RUN mkdir -p /prj \
  && mkdir -p /prj/docker-env

COPY docker-env /prj/docker-env

# php
RUN yum -y install epel-release
RUN rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
RUN cp /prj/docker-env/remi-php72.repo /etc/yum.repos.d/ && \
  yum install -y --enablerepo=remi-php72 php php-common php-opcache php-mbstring\
  php-xdebug php-mysql php-mysqlnd php-zip php-pdo php-cli \
  php-pgsql.x86_64 php-devel make gcc-c++ autoconf automake libtool

# composer
RUN curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/local/bin/composer

WORKDIR /prj
RUN git clone -b v1.27.2 https://github.com/grpc/grpc

WORKDIR /prj/grpc

RUN git submodule update --init

RUN make

RUN make install

# change gcc version 4.8 -> 7
RUN yum install -y centos-release-scl && \
  yum install -y devtoolset-7-gcc*
SHELL [ "/usr/bin/scl", "enable", "devtoolset-7"]

# gRPC - php ext
WORKDIR /prj/grpc/src/php/ext/grpc
RUN phpize && \
  ./configure && \
  make && \
  make install

SHELL ["/bin/bash", "-c"]

# Enable the gRPC extension in php.ini
RUN echo extension=grpc.so  >> /etc/php.ini

WORKDIR /prj

# Add gRPC as a Composer dependency
RUN composer global require "grpc/grpc"

# Installing the protobuf runtime library
RUN composer global require "google/protobuf"
WORKDIR /var/www/html
EXPOSE 80

#apache起動
# systemctl enable httpd.service && systemctl start httpd.service && chkconfig httpd.on

#確認
# systemctl status httpd