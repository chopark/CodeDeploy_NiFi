#!/bin/bash
cp .bash_aliases ../
sudo apt install openjdk-8-jdk -y
sudo apt install htop -y
sudo apt install iotop -y
sudo apt install iperf -y
sudo apt install cpustat -y
sudo apt install python3-pip
python3 -m pip install pandas

sudo dpkg -i jdk/*

#curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#unzip awscliv2.zip
sudo ./aws/install

aws configure
source ~/.bashrc
