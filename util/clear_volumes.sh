#!/bin/bash

# remove all exited containers
EXITED_CONTAINER_IDS=$(docker ps -a | grep Exit | awk '{ print $1 }')

if [ -n "${EXITED_CONTAINER_IDS}" ]
then
    sudo docker rm ${EXITED_CONTAINER_IDS}
fi

# remove all unused volumes
/usr/bin/expect << EOF
spawn sudo docker volume prune
expect "Are you sure you want to continue?"
send "y\n"
expect EOF
EOF
