FROM gwynethstark/arch-base-yay:latest
LABEL maintainer="Gwyneth Stark"

# Defining requirements
ENV pacman_packages="jre8-openjdk-headless jre11-openjdk-headless screen rsync moreutils"

# Defining AUR package
ENV aur_packages="forge-server"

# Adding supervisor config file for app
ADD build/*.conf /etc/supervisor/conf.d/

# Adding install script
ADD build/*.sh /root/

# Adding run scripts
ADD run/nobody/*.sh /home/nobody/

# Adding init script
ADD binhex/*.sh /usr/local/bin/

# Moving pre-configured config for forge
ADD config/ /home/nobody/

# Making scripts executable
RUN chmod +x /usr/local/bin/*.sh

# Installation
RUN chmod +x /root/*.sh && /bin/bash /root/install.sh

# Mapping /config to host config for persistence
VOLUME /config

# Exposing the port for Minecraft
EXPOSE 25565

CMD ["/usr/bin/bash","/usr/local/bin/init.sh"]