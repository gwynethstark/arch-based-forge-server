FROM archlinux
LABEL maintainer="Gwyneth Stark"

ENV yay_version=10.2.2-4

ADD build/*.sh /root/

RUN chmod +x /root/*.sh && /bin/bash /root/install.sh