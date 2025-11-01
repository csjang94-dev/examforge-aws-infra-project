#!/bin/bash
# Ubuntu용 Apache 실행 스크립트

# 로그/런타임 디렉토리 생성
mkdir -p /var/log/apache2 /var/run/apache2

# 포트 3000으로 변경
sed -i 's/Listen 80/Listen 3000/' /etc/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:3000>/' /etc/apache2/sites-available/000-default.conf

# DocumentRoot를 /var/www/html로 유지 (Ubuntu 기본값)
# 이미 설정되어 있으므로 추가 변경 불필요

# examforge 컨텐츠를 Apache 루트로 복사
if [ -d "/examforge" ]; then
    cp -r /examforge/* /var/www/html/ 2>/dev/null || true
fi

# 권한 설정
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Apache 설정 테스트
apache2ctl configtest

# Apache 시작 (포그라운드 실행)
exec apache2ctl -D FOREGROUND
