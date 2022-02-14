#!/bin/bash
docker build -f baxter_hardware_container . -t cloth_demo_baxter_gpu --build-arg ssh_prv_key="$(cat ~/.ssh/id_ed25519)" --build-arg ssh_pub_key="$(cat ~/.ssh/id_ed25519.pub)"
