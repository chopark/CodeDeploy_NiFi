#!/bin/bash
cp .bash_aliases ../
sudo apt-get install openjdk-8-jdk -y
sudo dpkg -i jdk/*
sudo apt-get install

sudo apt install awscli -y

aws configure
source ~/.bashrc
