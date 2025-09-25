FROM cloudflare/cloudflared:latest AS cloudflared-builder

FROM ubuntu:latest

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

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
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
    chmod +x /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/sbin/reboot && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone
    
ENTRYPOINT ["entrypoint.sh"]
