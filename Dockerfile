FROM osrf/ros:kinetic-desktop-full

ARG ssh_prv_key
ARG ssh_pub_key

RUN rm -rf /var/lib/apt/lists/*

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

# ==================
# below sourced from https://gitlab.com/nvidia/opengl/blob/ubuntu16.04/base/Dockerfile

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxau6:i386 \
        libxdmcp6 libxdmcp6:i386 \
        libxcb1 libxcb1:i386 \
        libxext6 libxext6:i386 \
        libx11-6 libx11-6:i386 && \
    rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# ==================
# below sourced from https://gitlab.com/nvidia/opengl/blob/ubuntu14.04/1.0-glvnd/runtime/Dockerfile

RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-utils && \
    apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        make \
        automake \
        autoconf \
        libtool \
        pkg-config \
        python \
        libxext-dev \
        libx11-dev \
        x11proto-gl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/libglvnd

RUN git clone --branch=v1.0.0 https://github.com/NVIDIA/libglvnd.git . && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/x86_64-linux-gnu && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/x86_64-linux-gnu -type f -name 'lib*.la' -delete

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        gcc-multilib \
        libxext-dev:i386 \
        libx11-dev:i386 && \
    rm -rf /var/lib/apt/lists/*

# 32-bit libraries
RUN make distclean && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/i386-linux-gnu --host=i386-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/i386-linux-gnu -type f -name 'lib*.la' -delete

COPY 10_nvidia.json /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    echo '/usr/local/lib/i386-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig

ENV LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# ==================
# below sourced from https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/8.0/runtime/Dockerfile

RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

ENV CUDA_VERSION_MAJOR=8.0 \
    CUDA_VERSION_MINOR=61 \
    CUDA_PKG_EXT=8-0
ENV CUDA_VERSION=$CUDA_VERSION_MAJOR.$CUDA_VERSION_MINOR
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-nvrtc-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-nvgraph-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-cusolver-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-cublas-dev-$CUDA_PKG_EXT=$CUDA_VERSION.2-1 \
        cuda-cufft-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-curand-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-cusparse-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-npp-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-cudart-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-misc-headers-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-toolkit-$CUDA_PKG_EXT=$CUDA_VERSION-1  && \
    ln -s cuda-$CUDA_VERSION_MAJOR /usr/local/cuda && \
    ln -s /usr/local/cuda-8.0/targets/x86_64-linux/include /usr/local/cuda/include && \
    rm -rf /var/lib/apt/lists/*

# nvidia-docker 1.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# nvidia-container-runtime
ENV NVIDIA_REQUIRE_CUDA="cuda>=$CUDA_VERSION_MAJOR"

# ROS Stuff
RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt-get update

#
RUN apt update && apt -y upgrade
RUN sudo apt install -y libcudnn6 libcudnn6-dev
    
SHELL ["/bin/bash", "-c"]
RUN echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc

# Package for installing Baxter
RUN sudo apt-get update && sudo apt-get install -y build-essential wget git \
# Astra packages
ros-$ROS_DISTRO-rgbd-launch ros-$ROS_DISTRO-libuvc ros-$ROS_DISTRO-libuvc-camera ros-$ROS_DISTRO-libuvc-ros \
# Move It
ros-kinetic-moveit \
#Fiducials
ros-kinetic-fiducials \
#Debugging
vim nano iproute2 net-tools inetutils-ping tree software-properties-common

RUN sudo add-apt-repository ppa:deadsnakes/ppa
RUN sudo apt update
RUN sudo apt install -y python3.6 python3.6-dev python3.6-tk
RUN curl https://bootstrap.pypa.io/get-pip.py | sudo -H python3.6
RUN pip3.6 install --upgrade pip
RUN pip3.6 install gitpython gitdb gym defusedxml tensorflow torch Keras h5py numpy scikit-image scikit-learn scipy rosdep rosinstall_generator wstool rosinstall roboticstoolbox-python opencv-python IPython pycocotools Pillow cython matplotlib imgaug rospkg catkin_pkg tqdm gdown 
#Setup and run the VM requirements
RUN pip3.6 install virtualenv virtualenvwrapper cython
#ENV venv_name=mclickrcnn
#CMD mkvirtualenv --python=python3 $venv_name
#RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py | sudo -H python
#RUN pip install rosdep tensorflow-gpu==1.4.1 Keras==2.1.2 h5py==2.7.0 enum34==1.1.2



WORKDIR /home/baxter/
RUN mkdir -p tools
WORKDIR tools
RUN wget https://github.com/davidfoerster/aptsources-cleanup/releases/download/v0.1.7.5.2/aptsources-cleanup.pyz
RUN chmod a+x aptsources-cleanup.pyz
RUN ./aptsources-cleanup.pyz -y
RUN apt update
RUN apt upgrade -y

#Installing baxter_sdk
WORKDIR /home/baxter
RUN mkdir -p hardware_ws/src
RUN mkdir -p simulated_ws/src
RUN mkdir -p openai_ws/src
WORKDIR hardware_ws/src
#Baxter firware needs release 1.1.1
RUN git clone -b release-1.1.1 https://github.com/AIResearchLab/baxter
WORKDIR /home/baxter/hardware_ws/src/baxter
# removing baxter entry in rosinstall file to avoid duplicate baxter_sdk folders
RUN sed -i '1,4d' baxter_sdk.rosinstall
RUN wstool init . baxter_sdk.rosinstall 
RUN wstool update
# replacing the default hostname with the hostname of the UC Baxter and changingthe distro to kinetic
RUN sed -i -e '22 s/baxter_hostname.local/011502P0001.local/g' -e '26 s/192.168.XXX.XXX/172.17.0.2/g'  -e '30 s/"indigo"/"kinetic"/g' baxter.sh
RUN mv baxter.sh ../..
WORKDIR /home/baxter/hardware_ws/src
#installing ROS Astra package
RUN git clone https://github.com/orbbec/ros_astra_camera
RUN git clone https://github.com/orbbec/ros_astra_launch
RUN git clone https://github.com/ros-planning/moveit_robots.git
RUN sed -i -e '16 s/value="0.1"/value="0.0"/g' /home/baxter/hardware_ws/src/moveit_robots/baxter/baxter_moveit_config/launch/trajectory_execution.launch
RUN git clone -b kinetic-devel https://github.com/UbiquityRobotics/fiducials
RUN git clone -b kinetic-devel https://github.com/ros-perception/vision_msgs

#Install the yolo program
#RUN git clone --recursive https://github.com/leggedrobotics/darknet_ros
#Install the requirements for mask rcnn
RUN git clone https://github.com/wjwwood/serial
RUN echo  "xterm*font:     *-fixed-*-*-*-18-*" > ~/.Xresources


RUN apt update
RUN apt upgrade -y

WORKDIR /home/baxter/hardware_ws
# it is neccesary to run 
#set the system bashrc variables# automatically sources the default ros on docker run
RUN echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.6" >> ~/.bashrc && echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc

WORKDIR /home/baxter/tools
RUN git clone https://github.com/FreeSpacenav/spacenavd.git
RUN git clone https://github.com/FreeSpacenav/libspnav.git
WORKDIR /home/baxter/tools/spacenavd
RUN ./configure && make install
WORKDIR /home/baxter/tools/libspnav
RUN ./configure && make install

RUN echo "export LD_LIBRARY_PATH=/home/baxter/hardware_ws/devel/lib:/opt/ros/kinetic/lib:/opt/ros/kinetic/lib/x86_64-linux-gnu:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:/usr/local/lib/" >> ~/.bashrc

RUN apt update && apt upgrade
RUN apt install -y python-pip xterm nautilus ros-kinetic-controller-manager ros-kinetic-four-wheel-steering-msgs ros-kinetic-urdf-geometry-parser ros-kinetic-joint-state* ros-kinetic-gazebo-ros-control ros-kinetic-joy ros-kinetic-pid ros-kinetic-ros-control ros-kinetic-effort-controllers python-rosdep python-catkin-tools python-wstool ssh xclip ros-kinetic-*rqt* ros-kinetic-turtlebot-gazebo python-click ros-kinetic-position-controllers

RUN pip2 install spnav rosdep rosinstall_generator wstool rosinstall catkin_pkg pyyaml empy rospkg numpy gitdb==0.6.4 gitpython==1.0.2 defusedxml gym==0.7.4

#This section also moves your host private key for ssh repositories
RUN apt update && \
    apt install -y \
        git \
        openssh-server \
        libmysqlclient-dev

# Authorize SSH Host
RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    ssh-keyscan github.com > /root/.ssh/known_hosts

# Add the keys and set permissions
RUN echo "$ssh_prv_key" > /root/.ssh/id_ed25519 && \
    echo "$ssh_pub_key" > /root/.ssh/id_ed25519.pub && \
    chmod 600 /root/.ssh/id_ed25519 && \
    chmod 600 /root/.ssh/id_ed25519.pub

#RUN ssh -T git@github.com

#end auto ssh test

WORKDIR /home/baxter/simulated_ws/src
RUN wstool init .
RUN wstool merge https://raw.githubusercontent.com/vicariousinc/baxter_simulator/kinetic-gazebo7/baxter_simulator.rosinstall
RUN wstool update
RUN rosdep install -y --from-paths . --ignore-src --rosdistro kinetic --as-root=apt:false
RUN git clone -b kinetic-devel https://github.com/AIResearchLab/control_msgs
RUN git clone -b kinetic-devel https://github.com/AIResearchLab/ros_controllers
RUN git clone https://github.com/wjwwood/serial


WORKDIR /home/baxter/openai_ws/src
RUN git clone -b version2 https://bitbucket.org/theconstructcore/openai_ros && \
    git clone -b version2 https://bitbucket.org/theconstructcore/openai_examples_projects && \
    git clone git@github.com:AIResearchLab/uc_deep_rl.git

RUN mkdir -p /home/baxter/openai_ws/src/deps
WORKDIR /home/baxter/openai_ws/src/deps
RUN git clone -b jade-devel https://github.com/ros-planning/navigation_msgs/ && \
    git clone https://bitbucket.org/theconstructcore/spawn_robot_tools && \
    git clone -b indigo-devel https://github.com/ros/geometry && \
    git clone -b indigo-devel https://github.com/ros/geometry2 && \
    git clone -b kinetic-devel https://github.com/ros-simulation/gazebo_ros_pkgs && \
    git clone -b indigo-devel https://github.com/ros/common_msgs
RUN mkdir -p /home/baxter/openai_ws/src/rl_envs
WORKDIR /home/baxter/openai_ws/src/rl_envs
RUN git clone -b kinetic-gazebo9 https://bitbucket.org/theconstructcore/turtlebot && \
    #git clone -b kinetic-gazebo7 https://bitbucket.org/theconstructcore/parrot_ardrone && \
    git clone https://bitbucket.org/theconstructcore/hopper


WORKDIR /home/baxter/simulated_ws/src
##This is also a test, lets observe if the system requires an ssh key or not
RUN git clone git@github.com:AIResearchLab/randle_description.git && \
    git clone git@github.com:AIResearchLab/randle-control.git

RUN pip3.6 install --upgrade pip
RUN pip3.6 install -U rosdep rosinstall_generator wstool rosinstall catkin_pkg pyyaml empy rospkg numpy

RUN apt update && apt upgrade -y


#Build HW WS
WORKDIR /home/baxter/hardware_ws
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; cd /home/baxter/hardware_ws; catkin_make'

WORKDIR /home/baxter/openai_ws

RUN echo '#!/bin/bash' > purge_learning_session.bash && \
    echo 'pkill gzserver' >> purge_learning_session.bash && \
    echo 'pkill roslaunch' >> purge_learning_session.bash && \
echo 'built purge script' && \
    echo '#!/bin/bash' > py3_catkin_make.bash && \
    echo 'echo Please run this from the simulated workspace' >> py3_catkin_make.bash && \
    echo 'rm -r devel build logs' >> py3_catkin_make.bash && \
    echo 'catkin config --extend /opt/ros/kinetic --cmake-args -DCMAKE_BUILD_TYPE=Release' >> py3_catkin_make.bash && \
    echo 'catkin build --cmake-args -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3.6 -DPYTHON_LIBRARY=/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu/libpython3.6m.so -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m' >> py3_catkin_make.bash && \
    echo 'source devel/setup.bash' >> py3_catkin_make.bash && \
echo 'built py3 build script' && \
    echo '#!/bin/bash' > catkin_make.bash  && \
    echo 'echo Please run this from the simulated workspace' >> catkin_make.bash && \
    echo 'rm -r devel build logs' >> catkin_make.bash && \
    echo 'catkin config --extend /opt/ros/kinetic --cmake-args -DCMAKE_BUILD_TYPE=Release' >> catkin_make.bash && \
    echo 'catkin build --cmake-args -DCMAKE_BUILD_TYPE=Release' >> catkin_make.bash  && \
    echo 'source devel/setup.bash' >> catkin_make.bash && \
echo 'built py2 build script' && \
    chmod +x py3_catkin_make.bash catkin_make.bash purge_learning_session.bash

#change this to a script and make it executable
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; cd /home/baxter/openai_ws; catkin config --extend /opt/ros/kinetic --cmake-args -DCMAKE_BUILD_TYPE=Release; catkin build --cmake-args -DCMAKE_BUILD_TYPE=Release'

WORKDIR /home/baxter/simulated_ws
#Build Sim WS, include catkin make script
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; cd /home/baxter/simulated_ws;catkin config --extend /opt/ros/kinetic --cmake-args -DCMAKE_BUILD_TYPE=Release; catkin build --cmake-args -DCMAKE_BUILD_TYPE=Release'


WORKDIR /home/baxter/openai_ws/src
#Go into the src examples and replace all references to /home/user/simulation_ws/ with baxter configurations
RUN /bin/bash -c 'cd /home/baxter/openai_ws/src;old_ws=/home/user/simulation_ws;new_ws=/home/baxter/openai_ws;find . -type f -name '*.yaml' | xargs sed -i "s%$old_ws%$new_ws%g"'
#Go into the OpenAI packages and do the same thing but for the python shebangs
RUN /bin/bash -c 'cd /home/baxter/openai_ws/src;old_shebang="#!/usr/bin/env python";new_shebang="#!/usr/bin/env python3.6";find . -type f -name '*.py' | xargs sed -i "s%$old_shebang%$new_shebang%g"'
RUN /bin/bash -c 'cd /home/baxter/openai_ws/src;old_shebang="#!/usr/bin/env python3.63.6";new_shebang="#!/usr/bin/env python3.6";find . -type f -name '*.py' | xargs sed -i "s%$old_shebang%$new_shebang%g"'

WORKDIR /home/baxter/openai_ws
RUN echo "source /home/baxter/hardware_ws/devel/setup.bash" >> ~/.bashrc
RUN echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
RUN echo "source /home/baxter/simulated_ws/devel/setup.bash" >> ~/.bashrc
RUN echo "source /home/baxter/openai_ws/devel/setup.bash" >> ~/.bashrc
RUN source ~/.bashrc
