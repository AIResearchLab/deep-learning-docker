#!/bin/bash
cat cmd.txt | xargs -I CMD --max-procs=9 bash -c CMD
