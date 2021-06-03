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

if [[ -z "${YOUR_IP}" ]]; then
  SYS_IP_ADDR=10.0.0.161
else
  SYS_IP_ADDR="${YOUR_IP}"
fi

xhost +local:docker

docker run --rm -it --name="dl_robotics" \
    --network=host \
    --add-host=011502P0001.local:10.0.0.10 \
    --device=/dev/dri:/dev/dri \
    --privileged -v /dev/bus/usb:/dev/bus/usb -e YOUR_IP=SYS_IP_ADDR \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --runtime=nvidia \
    --env="XAUTHORITY=$XAUTH" \
    --volume="$XAUTH:$XAUTH" \
    deep_learning_kit
    
