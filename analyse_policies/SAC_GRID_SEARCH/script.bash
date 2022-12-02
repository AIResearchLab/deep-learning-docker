#!/bin/bash
#xhost +local:docker
#docker exec -it deep_rl_gpu bash

#grid search algorithm on td3 approach

#establish variable hyperparameter tuning

for VARIABLE in 1 2 3 4 5 .. N
do
    for VARIABLE2 in 6 7 8 9 10 .. N
        do
            echo $VARIABLE -- $VARIABLE2
        done
done
