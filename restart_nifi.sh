HOME=/home/ubuntu
cd $HOME/jarvis_nifi/conf
IP=`hostname -i`

sed -i s/nifi.remote.input.host=.*/nifi.remote.input.host=$IP/ nifi.properties
sed -i s/nifi.web.http.host=.*/nifi.web.http.host=$IP/ nifi.properties
cd $HOME/jarvis_nifi/bin

sudo ./nifi.sh stop
rm -rf ../content_repository/* ../provenance_repository/* ../flowfile_repository/* ../state/local/* ../logs/*
if [ -d /mnt/ram_disk ]; then
	sudo rm -rf /mnt/ram_disk/*
fi

sudo ./nifi.sh start
