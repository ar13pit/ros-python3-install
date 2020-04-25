# syntax = docker/dockerfile:experimental
# -------------------------------------------------------------------
#       Dockerfile to build working Ubuntu image with ROS + Python3
# -------------------------------------------------------------------

# Set default base image to Ubuntu 18.04
ARG BASE_IMAGE=ubuntu:18.04
FROM $BASE_IMAGE

# Inform scripts that no questions should be asked and set some environment
# variables to prevent warnings and errors
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    DOCKER=true \
    USER=amigo \
    TERM=xterm-256color

# Set default shell to be bash
SHELL ["/bin/bash", "-c"]

# Install commands used in our scripts and standard present on a clean ubuntu
# installation and setup a user with sudo priviledges
RUN apt-get update -qq && \
    apt-get install -qq --assume-yes --no-install-recommends apt-transport-https apt-utils ca-certificates curl dbus dialog git lsb-release openssh-client sudo tzdata wget > /dev/null && \
    # Add amigo user
    adduser -u 1000 --disabled-password --gecos "" $USER && \
    usermod -aG sudo $USER && \
    usermod -aG adm $USER && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/"$USER"

# Setup the current user and its home directory
USER "$USER"
WORKDIR /home/"$USER"

ADD bootstrap.bash ./bootstrap.bash

RUN ./bootstrap.bash
