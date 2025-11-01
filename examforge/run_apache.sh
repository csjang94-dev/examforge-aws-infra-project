#!/bin/bash
# run_apache.sh
# 컨테이너에서 Apache HTTP 서버 실행 스크립트

# Apache 환경 변수 설정 (필요시)
APACHE_RUN_USER=www-data
APACHE_RUN_GROUP=www-data
APACHE_LOG_DIR=/var/log/apache2

# 로그 디렉토리 생성
mkdir -p $APACHE_LOG_DIR

# Apache 시작 (포그라운드 실행)
apache2ctl -D FOREGROUND
