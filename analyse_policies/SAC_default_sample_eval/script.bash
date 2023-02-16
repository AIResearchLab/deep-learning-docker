#!/bin/bash

echo 'please ensure this bash script is being run in the same directory'

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

dyna_img_name=$((RANDOM))"_TD3_eval"
xhost +local:docker
docker run --rm -t -d --name=$dyna_img_name \
    --network bridge \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --env="XAUTHORITY=$XAUTH" \
    --runtime=nvidia \
    --volume="$XAUTH:$XAUTH" \
    anaylsis_runtime_img

#Next create results
local_dir=$(pwd)
target_dir=$local_dir'/results'$dyna_img_name
mkdir $target_dir

#Execute learning
docker exec -it $dyna_img_name /bin/bash -c 'source /home/baxter/pyb_ws/devel/setup.bash;roslaunch randle_learner _sac.launch'

#Find the full path of the learning logs setup
echo "DELAY OF SAVE EXE"
sleep 3
echo "END DELAY"


echo 'TARGET DIRECTORY'
echo $target_dir

results_folder=$(docker exec -t -i $dyna_img_name /bin/bash -c 'ls -d /home/baxter/pyb_ws/src/learn*')

echo "FOUND FOLDER "
echo $results_folder

str_cmd="docker cp "
str_cmd+=$dyna_img_name
str_cmd+=":"
str_cmd+=$results_folder

str_cmd=${str_cmd//$'\n'/}
target_dir=${target_dir//$'\n'/}
str_cmd=${str_cmd//$'\r'/}
target_dir=${target_dir//$'\r'/}

echo "STRING_CMD: "
final_cmd=$str_cmd" "$target_dir
echo $final_cmd
echo "NOW ATTEMPTING TO STORING FILE"
eval $final_cmd

echo "KILLING CONTAINER"
docker kill $dyna_img_name
# cat <<<$str_cmd' '$target_dir > file.txt
