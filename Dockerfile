FROM ubuntu:16.04
MAINTAINER nsioo. <nsioo@outlook.com>

ENV DEBIAN_FRONTEND noninteractive


# 脚本存放
ADD provision.sh /docker/provision.sh
ADD setup.sh /docker/setup.sh
ADD serve.sh /docker/serve.sh

ADD supervisor.conf /etc/supervisor/conf.d/supervisor.conf


#主要命令
RUN chmod +x /docker/*.sh

RUN /docker/provision.sh


#启动脚本

EXPOSE 80 22 35729 9876

#CMD ["/usr/bin/supervisord"] 放到setup中执行
ENTRYPOINT ["/docker/setup.sh"]
