FROM cloudflare/cloudflared:latest

LABEL org.opencontainers.image.source="https://github.com/maojiaxing/cloudflared-docker"

ENV TZ=Asia/Shanghai \
    USER=cloudflare \
    PASSWORD=cloudflare!23 \
    TOKEN=''
    
COPY entrypoint.sh /entrypoint.sh
COPY reboot.sh /usr/local/sbin/reboot

RUN apk update && \
    apk add --no-cache tzdata openssh-server sudo curl ca-certificates wget vim net-tools supervisor cron unzip iputils-ping telnet git iproute2 jq gettext tzdata&& \
    rm -rf /var/cache/apk/* && \
    mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    # 创建SSH用户并设置密码
    chmod +x /entrypoint.sh && \
    chmod +x /usr/local/sbin/reboot && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

