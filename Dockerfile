FROM cloudflare/cloudflared:latest AS cloudflared-builder
RUN cp /usr/local/bin/cloudflared /tmp/cloudflared

FROM debian:12-slim

LABEL org.opencontainers.image.source="https://github.com/maojiaxing/cloudflared-docker"

ENV TZ=Asia/Shanghai \
    USER=cloudflare \
    PASSWORD=cloudflare!23 \
    PORT=22 \
    TOKEN=''

RUN mkdir -p /tmp/templates

COPY supervisord.conf /tmp/templates/supervisord.conf
COPY sshd.service /tmp/templates/sshd.service
COPY cloudflared.service /tmp/templates/cloudflared.service
COPY entrypoint.sh /entrypoint.sh
COPY reboot.sh /usr/local/sbin/reboot
COPY --from=cloudflared-builder /tmp/cloudflared /usr/local/bin/

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

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D" "-p" "$PORT"]
