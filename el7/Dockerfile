FROM litmusimage/centos:7 AS builder
ARG testuser1pw=changeme
LABEL org.opencontainers.image.source https://github.com/hsnodgrass/cme_litmusimages
ENV container docker
EXPOSE 22
VOLUME /run /tmp
STOPSIGNAL SIGRTMIN+3
CMD "/usr/sbin/init"
RUN echo "LC_ALL=en_US.utf-8" >> /etc/locale.conf && \
    rpm -U https://yum.puppet.com/puppet7-release-el-7.noarch.rpm && \
    yum install -y puppet-agent \
                   openssh-server \
                   openssh-clients \
                   initscripts \
                   glibc-langpack-en && \
    systemctl enable sshd.service

FROM builder
# Modify below
RUN yum install -y which \
                   NetworkManager
RUN useradd testuser1 && \
    echo -e "${testuser1pw}\n${testuser1pw}" | (passwd --stdin testuser1)
