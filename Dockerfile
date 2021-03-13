FROM osrf/ros:kinetic-desktop-full

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
        cuda-misc-headers-$CUDA_PKG_EXT=$CUDA_VERSION-1 && \
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
    apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116 && \
    apt-get update
    
SHELL ["/bin/bash", "-c"]
# automatically sources the default ros on docker run
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

#Install the nvidia toolkit, since Cuda is already installed this should not be nessisary, lets revisit and try to figure out
#RUN apt install -y nvidia-cuda-toolkit

RUN sudo add-apt-repository ppa:deadsnakes/ppa
RUN sudo apt-get update
RUN sudo apt-get install -y python3.6 python3.6-dev
RUN curl https://bootstrap.pypa.io/get-pip.py | sudo -H python3.6
RUN pip3.6 install -U h5py Keras numpy scikit-image scikit-learn scipy tensorflow-gpu=1.2.0 rosdep rosinstall_generator wstool rosinstall roboticstoolbox-python opencv-python

#Installing baxter_sdk
WORKDIR /home/baxter
RUN mkdir -p catkin_ws/src
WORKDIR catkin_ws
WORKDIR src
#Baxter firware needs release 1.1.1
RUN git clone -b release-1.1.1 https://github.com/AIResearchLab/baxter
WORKDIR baxter
# removing baxter entry in rosinstall file to avoid duplicate baxter_sdk folders
RUN sed -i '1,4d' baxter_sdk.rosinstall
RUN wstool init . baxter_sdk.rosinstall 
RUN wstool update
# replacing the default hostname with the hostname of the UC Baxter and changingthe distro to kinetic
RUN sed -i -e '22 s/baxter_hostname.local/011502P0001.local/g' -e '26 s/192.168.XXX.XXX/172.17.0.2/g'  -e '30 s/"indigo"/"kinetic"/g' baxter.sh
RUN mv baxter.sh ../..
WORKDIR ..
#installing ROS Astra package
RUN git clone https://github.com/orbbec/ros_astra_camera
RUN git clone https://github.com/orbbec/ros_astra_launch
RUN git clone https://github.com/ros-planning/moveit_robots.git
RUN sed -i -e '16 s/value="0.1"/value="0.0"/g' /home/baxter/catkin_ws/src/moveit_robots/baxter/baxter_moveit_config/launch/trajectory_execution.launch
RUN git clone -b kinetic-devel https://github.com/UbiquityRobotics/fiducials
RUN git clone -b kinetic-devel https://github.com/ros-perception/vision_msgs

RUN git clone -b kinetic-devel https://github.com/akio/mask_rcnn_ros
#Install the requirements for mask rcnn

WORKDIR /home/baxter/catkin_ws/src/mask_rcnn_ros/examples/
RUN /bin/bash -c './download_example_bag.sh'

#Next, we need to edit the mask_rcnn to account for our python setup, we import a python script for our specific purpose here
COPY mask_rcnn_node_UC_ver /home/baxter/catkin_ws/src/mask_rcnn_ros/nodes/mask_rcnn_node_UC_ver




WORKDIR /home/baxter/catkin_ws
# it is neccesary to run 
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; catkin_make'

#Now time for my changes to get the mask rcnn package up and running


# Install ROS packages
#RUN apt-get update && apt-get install -y \
#        ros-kinetic-xxx
#    rm -rf /var/lib/apt/lists/*

# Add new sudo user
#ENV USERNAME=username
#RUN useradd -m $USERNAME && \
#        echo "$USERNAME:$USERNAME" | chpasswd && \
#        usermod --shell /bin/bash $USERNAME && \
#        usermod -aG sudo $USERNAME && \
#        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
#        chmod 0440 /etc/sudoers.d/$USERNAME && \
#        usermod  --uid 1000 $USERNAME && \
#        groupmod --gid 1000 $USERNAME

# Uncomment to change default user and working directory
#USER rosmaster
#WORKDIR /home/rosmaster/
