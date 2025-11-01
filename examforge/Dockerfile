FROM public.ecr.aws/amazonlinux/amazonlinux:latest

# Apache와 curl 설치 (헬스체크용) - 충돌 해결
RUN yum update -y --allowerasing && \
    yum install -y httpd curl && \
    yum clean all && \
    rm -rf /var/cache/yum

# 컨텐츠 복사
COPY . /examforge/

# 스크립트 복사 및 실행 권한
COPY run_apache.sh /run_apache.sh
RUN chmod +x /run_apache.sh

# 작업 디렉토리
WORKDIR /var/www/html

# 포트 노출
EXPOSE 3000

# 헬스체크
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# 엔트리포인트
CMD ["/run_apache.sh"]
