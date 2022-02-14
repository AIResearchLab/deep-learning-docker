#!/bin/bash
docker build -f deep_rl_learning_motion . -t test_dep_rl_kinxen --build-arg ssh_prv_key="$(cat ~/.ssh/id_ed25519)" --build-arg ssh_pub_key="$(cat ~/.ssh/id_ed25519.pub)"
