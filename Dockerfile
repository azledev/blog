# Build
FROM hugomods/hugo:exts AS builder
WORKDIR /src
COPY . .
RUN git submodule update --init --recursive
RUN hugo --minify

# Serve
FROM nginx:alpine
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80