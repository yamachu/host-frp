FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y curl

ARG FRP_VERSION=0.62.0

RUN curl -L -o frp.tar.gz https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_arm64.tar.gz
RUN tar -zxvf frp.tar.gz && \
    mv frp_${FRP_VERSION}_linux_arm64/frps ./frps && \
    rm -rf frp_${FRP_VERSION}_linux_arm64 frp.tar.gz

COPY config/frps.toml ./

# Default token, MUST be changed
ENV FRP_AUTH_TOKEN="GQuuuuuuuuuuuuuuuuuuuuuuuuuuX"
EXPOSE 7000 8443

CMD ["./frps", "-c", "frps.toml"]
