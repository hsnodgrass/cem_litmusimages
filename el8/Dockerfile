FROM litmusimage/centos:8 AS builder
ARG testuser1pw=changeme
LABEL org.opencontainers.image.source https://github.com/hsnodgrass/cme_litmusimages
ENV container docker
EXPOSE 22
VOLUME /run /tmp
STOPSIGNAL SIGRTMIN+3
CMD "/usr/sbin/init"
RUN echo "LC_ALL=en_US.utf-8" >> /etc/locale.conf && \
    rpm -U https://yum.puppet.com/puppet7-release-el-8.noarch.rpm && \
    yum install -y puppet-agent \
                   openssh-server \
                   openssh-clients \
                   initscripts \
                   glibc-langpack-en && \
    systemctl enable sshd.service

FROM builder
# Modify below
RUN dnf install -y which \
                   NetworkManager \
                   nfs-utils \
                   ypserv \
                   postfix \
                   cups \
                   iptables-services \
                   httpd \
                   dovecot \
                   vsftpd \
                   samba \
                   net-snmp \
                   crypto-policies \
                   xorg-x11-server-Xorg \
                   rsync-daemon \
                   avahi \
                   passwd && \
    systemctl enable NetworkManager \
                     ypserv \
                     postfix \
                     cups \
                     iptables \
                     httpd \
                     dovecot \
                     vsftpd \
                     smb \
                     snmpd \
                     rsyncd \
                     avahi-daemon
RUN echo CRYPTO_POLICY= >> /etc/sysconfig/sshd && \
    useradd testuser1 && \
    echo -e "${testuser1pw}\n${testuser1pw}" | (passwd --stdin testuser1) && \
    sed -i 's/inet_interfaces = localhost/inet_interfaces = all/' /etc/postfix/main.cf && \
    update-crypto-policies --set LEGACY && update-crypto-policies