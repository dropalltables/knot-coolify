FROM golang:1.25-alpine AS builder
ENV KNOT_REPO_SCAN_PATH=/home/git/repositories
ENV CGO_ENABLED=1

ARG TAG='v1.11.0-alpha'

WORKDIR /app
RUN apk add git gcc musl-dev
RUN git clone -b ${TAG} https://tangled.org/@tangled.org/core .
RUN go build -o /usr/bin/knot -ldflags '-s -w -extldflags "-static"' ./cmd/knot

FROM alpine:latest
EXPOSE 5555
EXPOSE 22

LABEL org.opencontainers.image.title='knot'
LABEL org.opencontainers.image.description='data server for tangled'
LABEL org.opencontainers.image.source='https://tangled.org/@tangled.org/knot-docker'
LABEL org.opencontainers.image.url='https://tangled.org'
LABEL org.opencontainers.image.vendor='tangled.org'
LABEL org.opencontainers.image.licenses='MIT'

ARG UID=1000
ARG GID=1000

# Install packages first so /command/ dir exists before we symlink into it
RUN apk add --no-cache shadow s6-overlay execline openssl openssh git curl bash

# s6 with-contenv needs ash available in /command/
RUN ln -sf /bin/ash /command/ash

# Copy rootfs config (sshd configs, s6 service definitions)
COPY rootfs .
RUN chmod 755 /etc && \
    chmod -R 755 /etc/s6-overlay && \
    chmod +x /etc/s6-overlay/scripts/keys-wrapper && \
    chmod +x /etc/s6-overlay/scripts/create-sshd-host-keys

# Remove duplicate/conflicting sshd AuthorizedKeysCommand config
# tangled_sshd.conf already has the correct one via keys-wrapper
RUN rm /etc/ssh/sshd_config.d/authorized_keys_command.conf

# Create git user and directories
RUN groupadd -g $GID -f git && \
    useradd -u $UID -g $GID -d /home/git git && \
    openssl rand -hex 16 | passwd --stdin git && \
    mkdir -p /home/git/repositories && \
    chown -R git:git /home/git

# Copy knot binary
COPY --from=builder /usr/bin/knot /usr/bin/knot

# Create app dir for DB, owned by git
RUN mkdir -p /app && chown -R git:git /app

HEALTHCHECK --interval=60s --timeout=30s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:5555 || exit 1

ENTRYPOINT ["/init"]
