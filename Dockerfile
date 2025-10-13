from golang:1.24-alpine as builder
env KNOT_REPO_SCAN_PATH=/home/git/repositories
env CGO_ENABLED=1

arg TAG='v1.9.1-alpha'

workdir /app
run apk add git gcc musl-dev
run git clone -b ${TAG} https://tangled.sh/@tangled.sh/core .
run go build -o /usr/bin/knot -ldflags '-s -w -extldflags "-static"' ./cmd/knot

from alpine:edge
expose 5555
expose 22

label org.opencontainers.image.title='knot'
label org.opencontainers.image.description='data server for tangled'
label org.opencontainers.image.source='https://github.com/savely-krasovsky/knot-docker'
label org.opencontainers.image.url='https://tangled.sh'
label org.opencontainers.image.vendor='tangled.sh'
label org.opencontainers.image.licenses='MIT'

copy rootfs .
run chmod 755 /etc
run chmod -R 755 /etc/s6-overlay
run apk add shadow s6-overlay execline openssl openssh git curl bash
run useradd -d /home/git git && openssl rand -hex 16 | passwd --stdin git
run mkdir -p /home/git/repositories && chown -R git:git /home/git
copy --from=builder /usr/bin/knot /usr/bin
run mkdir /app && chown -R git:git /app

healthcheck --interval=60s --timeout=30s --start-period=5s --retries=3 \
    cmd curl -f http://localhost:5555 || exit 1

entrypoint ["/init"]
