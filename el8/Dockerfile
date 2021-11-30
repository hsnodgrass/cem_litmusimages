FROM litmusimage/centos:8 AS builder
ARG collection=puppet7
ARG firewallpkg=firewalld
ARG firewallsvc=firewalld
ARG testuser1pw=changeme
LABEL org.opencontainers.image.source https://github.com/hsnodgrass/cem_litmusimages
LABEL com.puppetlabs.litmus.os-release.name CentOS Linux
LABEL com.puppetlabs.litmus.os-release.version 8
LABEL com.puppetlabs.litmus.os-release.id centos
LABEL com.puppetlabs.litmus.os-release.id-like rhel fedora
LABEL com.puppetlabs.litmus.os-release.version-id 8
LABEL com.puppetlabs.litmus.os-release.platform-id platform:el8
LABEL com.puppetlabs.litmus.os-release.cpe-name cpe:/o:centos:centos:8
ENV container docker
EXPOSE 22
VOLUME /run /tmp
STOPSIGNAL SIGRTMIN+3
CMD "/usr/sbin/init"
RUN echo "LC_ALL=en_US.utf-8" >> /etc/locale.conf && \
    rpm -U https://yum.puppet.com/${collection}-release-el-8.noarch.rpm && \
    yum install -y puppet-agent \
                   openssh-server \
                   openssh-clients \
                   initscripts \
                   glibc-langpack-en \
                   ${firewallpkg} && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N "" && \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N "" && \
    sed -ri "s/^#?PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config && \
    sed -ri "s/^#?PasswordAuthentication .*/PasswordAuthentication yes/" /etc/ssh/sshd_config && \
    sed -ri "s/^#?UseDNS .*/UseDNS no/" /etc/ssh/sshd_config && \
    sed -e "/HostKey.*ssh_host_e.*_key/ s/^#*/#/" -ri /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd && \
    echo root:root | /usr/sbin/chpasswd && \
    systemctl enable sshd.service

FROM builder
# Modify below
RUN dnf install -y which \
                   NetworkManager \
                   nfs-utils \
                   ypserv \
                   postfix \
                   cups \
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
                     ${firewallsvc} \
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
