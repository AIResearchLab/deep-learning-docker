git clone https://github.com/AIResearchLab/cloth_sort /home/baxter/hardware_ws/src/cloth_sort
source /opt/ros/kinetic/setup.bash
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.6
source /usr/local/bin/virtualenvwrapper.sh
source /home/baxter/hardware_ws/devel/setup.bash
source /opt/ros/kinetic/setup.bash
export LD_LIBRARY_PATH=/home/baxter/hardware_ws/devel/lib:/opt/ros/kinetic/lib:/opt/ros/kinetic/lib/x86_64-linux-gnu:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu:/usr/local/lib/
catkin_make
cp /home/baxter/hardware_ws/src/cloth_sort/test.sh /home/baxter/hardware_ws
export EDITOR='code'
# xrdb -merge ~/.Xresources