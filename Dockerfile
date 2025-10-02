# Use Node 16 as base
FROM node:16

# Install curl, tar, git (for SCM checkout), and Docker CLI
ENV DOCKERVERSION=20.10.24
RUN apt-get update && apt-get install -y curl git tar \
    && curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
    && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 -C /usr/local/bin docker/docker \
    && rm docker-${DOCKERVERSION}.tgz \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set PATH to include Docker
ENV PATH="/usr/local/bin:${PATH}"
