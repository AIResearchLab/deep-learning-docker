#!/bin/bash
docker build -f Dockerfile_bashconfig . -t deep_learning_kit --build-arg ssh_prv_key="$(cat ~/.ssh/id_ed25519)" --build-arg ssh_pub_key="$(cat ~/.ssh/id_ed25519.pub)"
