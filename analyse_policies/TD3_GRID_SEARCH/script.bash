#!/bin/bash

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
docker run --rm -d --name="RL_eval" \
    --network none \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --env="XAUTHORITY=$XAUTH" \
    --runtime=nvidia \
    --volume="$XAUTH:$XAUTH" \
    anaylsis_runtime_img

docker exec -it anaylsis_runtime_img echo helloworld

docker kill anaylsis_runtime_img
