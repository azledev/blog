FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y git curl tar && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
RUN curl -L https://github.com/gohugoio/hugo/releases/download/v0.157.0/hugo_extended_0.157.0_linux-${TARGETARCH}.tar.gz \
    | tar -xz -C /usr/local/bin hugo

WORKDIR /src
COPY . .
RUN git submodule update --init --recursive
RUN hugo --minify

FROM nginx:alpine
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80