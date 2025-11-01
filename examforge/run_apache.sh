#!/bin/bash
# 컨테이너에서 Apache HTTP 서버 실행 스크립트

APACHE_RUN_USER=www-data
APACHE_RUN_GROUP=www-data
APACHE_LOG_DIR=/var/log/apache2

# 로그/락 디렉토리 생성
mkdir -p $APACHE_LOG_DIR /var/run/httpd /var/lock/httpd

# Apache 포트 3000으로 변경
sed -i 's/Listen 80/Listen 3000/' /etc/httpd/conf/httpd.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:3000>/' /etc/httpd/conf.d/*.conf

# Apache 시작 (포그라운드 실행)
/usr/sbin/httpd -D FOREGROUND
