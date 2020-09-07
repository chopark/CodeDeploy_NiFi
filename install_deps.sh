#!/bin/bash
cp .bash_aliases ../
sudo apt-get install openjdk-8-jdk -y
sudo apt-get install iperf -y
sudo dpkg -i jdk/*

#curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#unzip awscliv2.zip
sudo ./aws/install

aws configure
source ~/.bashrc
