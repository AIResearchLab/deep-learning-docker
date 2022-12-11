#!/bin/bash

echo 'please ensure this bash script is being run in the same directory'
#First create results
if [ -d "./results" ] 
then
    echo "Directory ./results exists."
    exit 0 
else
    echo "Creating results folder"
    mkdir results
fi


#The loop activation
XAUTH=/tmp/.docker.xauth
if [ ! -f $XAUTH ]
then
    xauth_list=$(xauth nlist :0 | sed -e 's/^..../ffff/')
    if [ ! -z "$xauth_list" ]
    then
        echo $xauth_list | xauth -f $XAUTH nmerge -
    else
        touch $XAUTH
    fi
    chmod a+r $XAUTH
fi

xhost +local:docker
docker run --rm -t -d --name="TD3_grid_eval" \
    --network none \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --env="XAUTHORITY=$XAUTH" \
    --runtime=nvidia \
    --volume="$XAUTH:$XAUTH" \
    anaylsis_runtime_img

#Execute learning
docker exec -it TD3_grid_eval /bin/bash -c 'echo helloworld;sleep 3;echo helloworld3'

#Find the full path of the learning logs setup
docker exec -it TD3_grid_eval /bin/bash -c 'cd /home/baxter/'

docker cp TD3_grid_eval:/file/path/within/container resu



docker kill TD3_grid_eval
