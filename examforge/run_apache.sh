#!/bin/bash
# 컨테이너에서 Apache HTTP 서버 실행 스크립트

# 로그/락 디렉토리 생성
mkdir -p /var/log/httpd /var/run/httpd /var/lock/httpd

# Apache 포트 3000으로 변경
sed -i 's/Listen 80/Listen 3000/' /etc/httpd/conf/httpd.conf

# DocumentRoot를 /var/www/html로 설정 (표준 위치)
sed -i 's#DocumentRoot "/var/www"#DocumentRoot "/var/www/html"#' /etc/httpd/conf/httpd.conf
sed -i 's#<Directory "/var/www">#<Directory "/var/www/html">#' /etc/httpd/conf/httpd.conf

# examforge 컨텐츠를 Apache 루트로 복사
cp -r /examforge/* /var/www/html/ 2>/dev/null || true

# 권한 설정
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Apache 설정 테스트
httpd -t

# Apache 시작 (포그라운드 실행)
exec /usr/sbin/httpd -D FOREGROUND
