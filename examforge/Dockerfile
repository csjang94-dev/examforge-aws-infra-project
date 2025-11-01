FROM public.ecr.aws/amazonlinux/amazonlinux:latest

RUN yum update -y && \
    yum install -y httpd

WORKDIR /var/www/html

COPY . /var/www/html

RUN echo 'mkdir -p /var/run/httpd' >> /root/run_apache.sh && \
    echo 'mkdir -p /var/lock/httpd' >> /root/run_apache.sh && \
    echo '/usr/sbin/httpd -D FOREGROUND' >> /root/run_apache.sh && \
    chmod 755 /root/run_apache.sh

EXPOSE 80

CMD ["/root/run_apache.sh"]

