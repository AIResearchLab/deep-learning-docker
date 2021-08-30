FROM osrf/ros:kinetic-desktop-full

ARG ssh_prv_key
ARG ssh_pub_key


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
RUN echo "$ssh_prv_key" > ~/.ssh/id_ed25519 && \
    echo "$ssh_pub_key" > ~/.ssh/id_ed25519.pub && \
    chmod 600 ~/.ssh/id_ed25519 && \
    chmod 600 ~/.ssh/id_ed25519.pub
    
# ROS Stuff
RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt-get update

#
RUN apt update && apt -y upgrade
    
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
RUN pip3.6 install gitpython gitdb gym==0.9.7 defusedxml tensorflow torch Keras h5py numpy scikit-image scikit-learn scipy rosdep rosinstall_generator wstool rosinstall roboticstoolbox-python opencv-python IPython pycocotools Pillow cython matplotlib imgaug rospkg catkin_pkg tqdm gdown pybullet 
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

RUN apt update
RUN apt upgrade -y

WORKDIR /home/baxter/tools
RUN git clone https://github.com/FreeSpacenav/spacenavd.git
RUN git clone https://github.com/FreeSpacenav/libspnav.git
WORKDIR /home/baxter/tools/spacenavd
RUN ./configure && make install
WORKDIR /home/baxter/tools/libspnav
RUN ./configure && make install

###Section Install pybullet library and pybullet robots + pybullet_gym
RUN mkdir -p /home/baxter/pyBulletRobotics
WORKDIR /home/baxter/pyBulletRobotics
RUN git clone https://github.com/benelot/pybullet-gym && git clone https://github.com/AIResearchLab/pybullet_robots
RUN echo "export PYBULLET_DIR=/home/baxter/pyBulletRobotics" >> ~/.bashrc
WORKDIR /home/baxter/pyBulletRobotics/pybullet-gym
RUN pip3.6 install -e .


RUN apt update && apt upgrade
RUN apt install -y python-pip xterm nautilus ros-kinetic-controller-manager ros-kinetic-four-wheel-steering-msgs ros-kinetic-urdf-geometry-parser ros-kinetic-joint-state* ros-kinetic-gazebo-ros-control ros-kinetic-joy ros-kinetic-pid ros-kinetic-ros-control ros-kinetic-effort-controllers python-rosdep python-catkin-tools python-wstool ssh xclip ros-kinetic-*rqt* ros-kinetic-turtlebot-gazebo python-click ros-kinetic-position-controllers

RUN pip2 install spnav rosdep rosinstall_generator wstool rosinstall catkin_pkg pyyaml empy rospkg numpy gitdb==0.6.4 gitpython==1.0.2 defusedxml

RUN pip3.6 install --upgrade pip
RUN pip3.6 install -U rosdep rosinstall_generator wstool rosinstall catkin_pkg pyyaml empy rospkg numpy

RUN apt update && apt upgrade -y

#create pybullet rl based ws, requirements include the core randle system, communication protocal and msgs
RUN mkdir -p /home/baxter/pyb_ws/src
WORKDIR /home/baxter/pyb_ws/src
RUN git clone git@github.com:AIResearchLab/randle_serial.git && \
git clone git@github.com:AIResearchLab/randle_core.git && \
git clone https://github.com/wjwwood/serial && \
git clone -b kinetic-devel https://github.com/RethinkRobotics/baxter_common
#RUN wstool init .
#RUN wstool merge https://raw.githubusercontent.com/vicariousinc/baxter_simulator/kinetic-gazebo7/baxter_simulator.rosinstall
#RUN wstool update
#RUN rosdep install -y --from-paths . --ignore-src --rosdistro kinetic --as-root=apt:false

WORKDIR /home/baxter/pyb_ws
RUN echo '#!/bin/bash' > catkin_make.bash  && \
    echo 'echo Please run this from the simulated workspace' >> catkin_make.bash && \
    echo 'rm -r devel build logs' >> catkin_make.bash && \
    echo 'catkin config --extend /opt/ros/kinetic --cmake-args -DCMAKE_BUILD_TYPE=Release' >> catkin_make.bash && \
    echo 'catkin build --cmake-args -DCMAKE_BUILD_TYPE=Release' >> catkin_make.bash  && \
    echo 'source devel/setup.bash' >> catkin_make.bash && \
echo 'built py2 build script' && \
    chmod +x catkin_make.bash
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; cd /home/baxter/pyb_ws; catkin config --extend /opt/ros/kinetic --cmake-args -DCMAKE_BUILD_TYPE=Release; catkin build --cmake-args -DCMAKE_BUILD_TYPE=Release'


WORKDIR /home/baxter/
RUN source ~/.bashrc

ENTRYPOINT /bin/bash -c 'cd /home/baxter/pyb_ws/src/randle_core;git pull;cd /home/baxter/pyb_ws/src/randle_serial;git pull;cd /home/baxter/pyBulletRobotics/pybullet_robots;git pull' && /bin/bash
