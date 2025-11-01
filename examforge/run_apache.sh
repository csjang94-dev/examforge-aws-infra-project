#!/bin/bash
# run_apache.sh
# 컨테이너에서 Apache HTTP 서버 실행 스크립트

# ---------------------------
# Apache 환경 변수
# ---------------------------
APACHE_RUN_USER=www-data
APACHE_RUN_GROUP=www-data
APACHE_LOG_DIR=/var/log/apache2

# ---------------------------
# 로그 디렉토리 생성
# ---------------------------
mkdir -p $APACHE_LOG_DIR
mkdir -p /var/run/httpd /var/lock/httpd

# ---------------------------
# Apache 포트 3000으로 변경 (ECS TargetGroup과 일치)
# ---------------------------
sed -i 's/Listen 80/Listen 3000/' /etc/httpd/conf/httpd.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:3000>/' /etc/httpd/conf.d/*.conf

# ---------------------------
# Apache 시작 (포그라운드 실행)
# ---------------------------
/usr/sbin/httpd -D FOREGROUND
