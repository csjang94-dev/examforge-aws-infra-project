FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Apache, curl 설치
RUN apt-get update && \
    apt-get install -y apache2 curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 컨텐츠 복사
COPY . /var/www/html/

# Apache 포트 3000으로 변경
RUN sed -i 's/Listen 80/Listen 3000/' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:3000>/' /etc/apache2/sites-available/000-default.conf

# 권한 설정
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# 로그 디렉토리 생성
RUN mkdir -p /var/log/apache2 /var/run/apache2

WORKDIR /var/www/html
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Apache 직접 실행
CMD ["apache2ctl", "-D", "FOREGROUND"]
