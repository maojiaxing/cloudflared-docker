FROM cloudflare/cloudflared:latest AS cloudflared-builder

FROM debian:12-slim

LABEL org.opencontainers.image.source="https://github.com/maojiaxing/cloudflared-docker"

ENV TZ=Asia/Shanghai \
    USER=cloudflare \
    PASSWORD=cloudflare!23 \
    PORT=22 \
    TUNNEL_TOKEN=''

RUN mkdir -p /tmp/templates

COPY supervisord.conf /tmp/supervisord.conf
COPY sshd.service /tmp/sshd.service
COPY cloudflared.service /tmp/cloudflared.service
COPY .bashrc /tmp/bashrc
COPY .profile /tmp/profile

COPY entrypoint.sh /entrypoint.sh
COPY reboot.sh /usr/local/sbin/reboot
COPY --from=cloudflared-builder /usr/local/bin/cloudflared /usr/local/bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    sudo \
    curl \
    ca-certificates \ 
    wget \
    vim \
    net-tools \ 
    supervisor \
    cron \
    unzip \
    iputils-ping \ 
    telnet \
    git \
    iproute2 \ 
    jq \
    gettext \ 
    tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    chmod +x /usr/local/bin/cloudflared && \
    chmod +x /entrypoint.sh && \
    chmod +x /usr/local/sbin/reboot && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

RUN adduser --disabled-password --home "/home/$USER" --shell /bin/bash --gecos "" "$USER"
RUN echo "$USER:$PASSWORD" | chpasswd
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USER && chmod 440 /etc/sudoers.d/$USER
RUN mkdir -p /var/run/sshd && echo "Port $PORT" >> /etc/ssh/sshd_config \ 
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config && chmod 600 /etc/ssh/sshd_config && chown root:root /etc/ssh/sshd_config
    
USER $USER

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D" "-p" "$PORT"]
