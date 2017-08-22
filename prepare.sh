#!/bin/bash
#
# prepare running docker container for services
# runs each time container starts

PARAMS="$@"

#create initial config
sed -i "s/DAEMON_ARGS=.*/DAEMON_ARGS=-d200/" /etc/init.d/bareos-sd
newNAME=dockerbar
rm -rf /etc/bareos/*
rm -f /etc/bareos/.rndpwd
mkdir -p /backup/file
mkdir -p /etc/bareos/bareos-fd.d/bareos-fd
mkdir -p /etc/bareos/bareos-sd.d/bareos-sd
cat << EOF > /etc/bareos/bareos-fd.d/bareos-fd/filedaemon.conf
FileDaemon {
  Name = ${newNAME}-fd
  Heartbeat Interval = 60
}

Director {
  Name = devbardir01-dir
  Password = "bareosfiledaemonclientinsidedockercontainer"
}

Messages {
  Name = Standard
  director = devbardir01-dir = all, !skipped, !restored
}
EOF

cat << EOF > /etc/bareos/bareos-sd.d/bareos-sd/storage.conf
Storage {
  Name = ${newNAME}-sd
  Maximum Concurrent Jobs = 1
  Heartbeat Interval = 60
}

Director {
  Name = devbardir01-dir
  Password = "bareosstoragedaemoninsidedockercontainer"
}

Device {
  Name = ${newNAME}Drive01
  Media Type = File
  Archive Device = /backup/file
  LabelMedia = yes;
  Random Access = yes;
  AutomaticMount = yes;
  RemovableMedia = no;
  AlwaysOpen = no;
  Maximum Concurrent Jobs = 1;
}

Messages {
  Name = Standard
  director = devbardir01-dir = all
}
EOF

echo "$(date '+%Y-%m-%d %H:%M:%S') Start Daemons" >>/var/log/bareos/bareos.log
#fix permissions
chown -R bareos:bareos /etc/bareos /var/log/bareos /backup

#run services
service bareos-sd stop && service bareos-sd start
service bareos-fd stop && service bareos-fd start

exec $PARAMS
