# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/jessie64"

#  config.vm.synced_folder "/vagrant", type: "rsync", rsync__exclude: ".git/"

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo deb https://apt.dockerproject.org/repo debian-jessie main > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get upgrade -y
    apt-get install -y git build-essential pkg-config zlib1g-dev libglib2.0-dev libpixman-1-dev docker-engine vim
    gpasswd -a vagrant docker
    service docker restart
  SHELL
end
