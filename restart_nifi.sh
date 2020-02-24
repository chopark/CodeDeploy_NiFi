cd /home/ubuntu/jarvis-nifi/conf
IP=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

sed -i s/nifi.remote.input.host=.*/nifi.remote.input.host=$IP/ nifi.properties
sed -i s/nifi.web.http.host=.*/nifi.web.http.host=$IP/ nifi.properties
cd /home/ubuntu/jarvis-nifi/bin
rm -rf ../content_repository/* ../provenance_repository/* ../flowfile_repository/* ../state/local/* ../logs/*
sudo ./nifi.sh start
