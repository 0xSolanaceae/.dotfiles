FROM nginx:alpine

# Install Tailscale
RUN apk add --no-cache curl iptables \
    && curl -fsSL https://pkgs.tailscale.com/stable/alpine/tailscale.apk -o /tmp/tailscale.apk \
    && apk add --no-cache /tmp/tailscale.apk \
    && rm /tmp/tailscale.apk

COPY migration.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["sh", "-c", "tailscaled & tailscale up --authkey=${TAILSCALE_AUTH_KEY} --hostname=${TAILSCALE_HOSTNAME} && nginx -g 'daemon off;'"]