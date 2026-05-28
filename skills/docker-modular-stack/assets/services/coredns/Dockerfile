FROM alpine:3.20

ARG PLUGIN_VERSION=0.6.1

RUN apk add --no-cache ca-certificates curl

RUN curl -fsSL "https://github.com/dokku/coredns-docker/releases/download/${PLUGIN_VERSION}/coredns-docker-linux-amd64" \
    -o /coredns && \
    chmod +x /coredns && \
    apk del curl

EXPOSE 53/tcp 53/udp
ENTRYPOINT ["/coredns"]
CMD ["-conf", "/Corefile"]
