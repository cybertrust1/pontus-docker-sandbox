FROM centos/systemd
MAINTAINER Leo Martins lmartins@pontusnetworks.com
ARG home=/root
ENV container docker

ENV TERM=xterm-color
RUN  yum -y update && yum install -y java && yum clean all && rm -rf /var/cache/yum

COPY pontus-hbase.service pontus-keycloak.service pontus-knox.service pontus-gui.service pontus-elastic.service pontus-graph.service pontus-nifi.service /etc/systemd/system/

RUN useradd -ms /bin/bash pontus && \
    systemctl enable samba  && \
    systemctl enable pontus-zookeeper.service  && \
    systemctl enable pontus-hbase-master.service  && \
    systemctl enable pontus-hbase-region.service  && \
    systemctl enable pontus-kafka.service  && \
    systemctl enable pontus-elastic.service  && \
    systemctl enable pontus-graph.service  && \
    systemctl enable pontus-graph-nifi.service  && \
    systemctl enable pontus-nifi.service  && \
    systemctl enable pontus-gui.service  && \
    systemctl enable pontus-keycloak.service  && \
    systemctl enable pontus-nginx.service 

EXPOSE 8443 5005-5010
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]

