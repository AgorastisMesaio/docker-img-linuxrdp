# Dockerfile for NetKit
#
# This Dockerfile sets up a minimal Alpine Linux container that can be
# used as a Remote Desktop. Includes a xrdp server with xfce4 and Chromium.
# Supports connections through RDP or VLC. Audio is working.
#

# Start from alpine base image
FROM alpine:latest

# Update Alpine and install necessary packages
RUN apk update && apk add --no-cache \
    xrdp xorgxrdp xorg-server xfce4 xfce4-terminal  \
	eudev dbus dbus-x11 \
    sudo supervisor \
    pulseaudio pulseaudio-utils alsa-utils alsa-lib alsa-plugins-pulse \
    x11vnc openssh util-linux \
	faenza-icon-theme slim xauth xf86-input-synaptics  firefox-esr \
	bash \
    xfce4-pulseaudio-plugin \
    xfce4-terminal \
    xinit \
    nano \
    alpine-conf \
    libpulse pulsemixer pavucontrol \
    chromium

# Clean up
RUN rm -fr /tmp/* /var/cache/apk/*

#     paper-gtk-theme \
#     paper-icon-theme \
#     setxkbmap \
#     thunar-volman \
#     ttf-freefont \
#     vim \
#     wireshark \
#     vlc-qt \
#     xf86-input-synaptics \
#     xfce4 \
#     xf86-input-mouse \
#     xf86-input-keyboard \
#     xfce4-screensaver lightdm-gtk-greeter \

# Rewrite the motd
RUN echo "Welcome to Linux remote desktop !" > /etc/motd

# Prepare custom files
RUN mkdir /etc/supervisor.d
ADD etc /etc
RUN chmod 755 /etc/xrdp/startwm.sh

# Needed for our custom nanorc
RUN mkdir /root/.nano

# Create the /usr/bin/confcat file with heredocs
RUN cat <<'EOF' > /usr/bin/confcat
#!/bin/bash
#
# confcat: removes lines with comments, very useful as a substitute
# for the "cat" program when we want to see only the effective lines,
# not the lines that have comments.

grep -vh '^[[:space:]]*#' "$@" | grep -v '^//' | grep -v '^;' | grep -v '^$'
EOF
RUN chmod +x /usr/bin/confcat

# Create the /usr/bin/e file with heredocs
RUN cat <<'EOF' > /usr/bin/e
#!/bin/bash
nano "${*}"
EOF
RUN chmod +x /usr/bin/e

# Prepare dbus
RUN mkdir -p /run/dbus/ && chown messagebus:messagebus /run/dbus/

# Prepare xrdp 2048 bit rsa key...
RUN xrdp-keygen xrdp auto

# SSH
#RUN ssh-keygen -A

# In parallel su must be suid to work properly
RUN chmod u+s /bin/su

# Ensure that each Docker container has a unique machine identifier,
# which might be useful for the reliable operation of some services
RUN uuidgen > /etc/machine-id

# set keyboard for QT Applications
RUN echo "export QT_XKB_CONFIG_ROOT=/usr/share/X11/locale" >> /etc/profile

# Expose RDP, VLC, Supervisor, SSH Protocols
EXPOSE 3389
#EXPOSE 5900 (Future VLC, not yet tested)
EXPOSE 9001
EXPOSE 22

# Copy entrypoint and htmlgenerator scripts
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# The CMD line represent the Arguments that will be passed to the
# /entrypoint.sh. We'll use them to indicate the script what
# command will be executed through our entrypoint when it finishes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
