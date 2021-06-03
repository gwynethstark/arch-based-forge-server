FROM gwynethstark/arch-base-yay:latest
LABEL maintainer="Gwyneth Stark"

# Defining requirements
ENV pacman_packages="jre8-openjdk-headless jre11-openjdk-headless screen rsync"

# Defining AUR package
ENV aur_packages="forge-server"

# Adding install script
ADD build/*.sh /root/

# Adding init script
ADD binhex/*.sh /usr/local/bin/

# Installation
RUN chmod +x /root/*.sh && /bin/bash /root/install.sh

# Mapping /config to host config for persistence
VOLUME /config

# Exposing the port for Minecraft
EXPOSE 25565

CMD ["/usr/bin/bash"]