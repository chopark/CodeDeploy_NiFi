sudo DEBIAN_FRONTEND=noninteractive apt-get -yq purge openjdk-8-jre openjdk-8-jre-headless
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install ca-certificates-java
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install libxrandr2 libxinerama1 libgl1-mesa-glx libgl1 libgtk2.0-0 libasound2 libgif7 libpulse0
sudo dpkg -i *
