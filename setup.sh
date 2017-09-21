#!/usr/bin/env bash


# 启动项
bash -c /usr/bin/supervisord




# 检查已经设定的变凉是否被重设
#http://www.xuebuyuan.com/2221628.html 

# 用户名

if [ ${USER_PASSWD} ]; then
	usermod -p $(echo ${USER_PASSWD} | openssl passwd -1 -stdin) root
	usermod -p $(echo ${USER_PASSWD} | openssl passwd -1 -stdin) homestead
fi

# 自己定义的运行文件
if [ ${START_SCRIPT} ] && [ -e ${START_SCRIPT} ] ; then
	/bin/sh -c ${START_SCRIPT};
fi