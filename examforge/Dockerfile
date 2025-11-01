FROM public.ecr.aws/amazonlinux/amazonlinux:latest

# ---------------------------
# Apache 설치
# ---------------------------
RUN yum update -y && \
    yum install -y httpd && \
    yum clean all

# ---------------------------
# 작업 디렉터리
# ---------------------------
WORKDIR /app

# ---------------------------
# 앱 파일 복사
# ---------------------------
COPY . /app

# ---------------------------
# run_apache.sh 생성 및 실행 권한
# ---------------------------
RUN echo '#!/bin/bash' > /app/run_apache.sh && \
    echo 'mkdir -p /var/run/httpd /var/lock/httpd' >> /app/run_apache.sh && \
    echo 'sed -i "s/Listen 80/Listen 3000/" /etc/httpd/conf/httpd.conf' >> /app/run_apache.sh && \
    echo 'sed -i "s/<VirtualHost \\*:80>/<VirtualHost \\*:3000>/" /etc/httpd/conf.d/*.conf' >> /app/run_apache.sh && \
    echo '/usr/sbin/httpd -D FOREGROUND' >> /app/run_apache.sh && \
    chmod +x /app/run_apache.sh

# ---------------------------
# 컨테이너 포트
# ---------------------------
EXPOSE 3000

# ---------------------------
# Fargate 실행 시 엔트리포인트
# ---------------------------
CMD ["/app/run_apache.sh"]
