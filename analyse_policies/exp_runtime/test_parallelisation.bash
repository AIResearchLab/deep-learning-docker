#!/bin/bash
#parallel --jobs 6 < cmds.txt
cat cmds.txt | xargs -I CMD --max-procs=6 bash -c CMD
docker stop $(docker ps -a -q)
