FROM golang:1.17.7-buster

# Needed in order to update since apk update configures tzdata.
RUN ln -sf /usr/share/zoneinfo/UTC > /etc/localtime

RUN apt -y update

# Install the Docker client and Git (needed by 'go install')
# Note that you'll need to make sure that /var/run/docker.sock is bind-mounted
# to this container in order for ACT to work.
RUN apt -y install docker git

# Install Act.
RUN go install "github.com/nektos/act@v0.2.25"

# Copy our documentation into the image.
COPY . /app
WORKDIR /app

ENTRYPOINT [ "act", "-P", "ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest" ]
