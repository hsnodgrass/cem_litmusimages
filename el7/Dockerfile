FROM litmusimage/centos:7 AS builder
ARG collection=puppet7
ARG testuser1pw=changeme
LABEL org.opencontainers.image.source https://github.com/hsnodgrass/cme_litmusimages
LABEL com.puppetlabs.litmus.os-release.name CentOS Linux
LABEL com.puppetlabs.litmus.os-release.version 7
LABEL com.puppetlabs.litmus.os-release.id centos
LABEL com.puppetlabs.litmus.os-release.id-like rhel fedora
LABEL com.puppetlabs.litmus.os-release.version-id 7
LABEL com.puppetlabs.litmus.os-release.platform-id platform:el7
LABEL com.puppetlabs.litmus.os-release.cpe-name cpe:/o:centos:centos:7
ENV container docker
EXPOSE 22
VOLUME /run /tmp
STOPSIGNAL SIGRTMIN+3
CMD "/usr/sbin/init"
RUN echo "LC_ALL=en_US.utf-8" >> /etc/locale.conf && \
    rpm -U https://yum.puppet.com/${collection}-release-el-7.noarch.rpm && \
    yum install -y puppet-agent \
                   openssh-server \
                   openssh-clients \
                   initscripts \
                   glibc-langpack-en && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N "" && \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N "" && \
    sed -ri "s/^#?PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config && \
    sed -ri "s/^#?PasswordAuthentication .*/PasswordAuthentication yes/" /etc/ssh/sshd_config && \
    sed -ri "s/^#?UseDNS .*/UseDNS no/" /etc/ssh/sshd_config && \
    sed -e "/HostKey.*ssh_host_e.*_key/ s/^#*/#/" -ri /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
    echo root:root | /usr/sbin/chpasswd && \
    systemctl enable sshd.service

FROM builder
# Modify below
RUN yum install -y which \
                   NetworkManager
RUN useradd testuser1 && \
    echo -e "${testuser1pw}\n${testuser1pw}" | (passwd --stdin testuser1)
