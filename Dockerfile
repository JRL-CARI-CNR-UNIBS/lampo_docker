FROM navigation2:rolling

ARG set__ros_domain_id=15
ARG set__gz_version=harmonic

RUN mkdir -p /home/gino/.gz/fuel
COPY ./fuel /home/gino/.gz/fuel

# GUI: Gazebo e RViz2
RUN sudo apt-get update
RUN sudo apt-get install -y lsb-release wget gnupg git gdb
RUN sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg &&\
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null &&\
    sudo apt-get update &&\
    sudo apt-get install -y gz-harmonic ros-rolling-rviz2
ENV GZ_VERSION ${set__gz_version}

# Roba varia
RUN apt-get install -y  ros-rolling-backward-ros\
                                          ros-rolling-pcl-ros\
                                          ros-rolling-control-toolbox\
                                          ros-rolling-generate-parameter-library\
                                          ros-rolling-ur\
                                          ros-rolling-actuator-msgs\
                                          ros-rolling-geometry-msgs\
                                          ros-rolling-gps-msgs\
                                          ros-rolling-nav-msgs\
                                          ros-rolling-rosgraph-msgs\
                                          ros-rolling-sensor-msgs\
                                          ros-rolling-std-msgs\
                                          ros-rolling-tf2-msgs\
                                          ros-rolling-trajectory-msgs\
                                          ros-rolling-vision-msgs\
                                          xterm

WORKDIR /opt
RUN mkdir -p lampo_ws/src

WORKDIR /opt/lampo_ws
COPY ./src ./src
RUN cd src\
    && git clone https://github.com/ros-controls/gz_ros2_control\
    && apt-get install -y ros-rolling-ros2-control
RUN cd ./src && git clone https://github.com/gazebosim/ros_gz.git -b iron
RUN . /opt/overlay_ws/install/setup.sh && colcon build --symlink-install --continue-on-error --cmake-args -DCMAKE_CXX_FLAGS="-w"
RUN mkdir -p /home/gino/ROS/lampo_ws_ros2_rolling/install/ur_description/share/ \
    && cp -r /opt/ros/rolling/share/ur_description /home/gino/ROS/lampo_ws_ros2_rolling/install/ur_description/share/
RUN mkdir -p /home/gino/ROS/lampo_ws_ros2_rolling/install/lampo_description/share/ \
    && ln -s /opt/lampo_ws/install/lampo_description/share/lampo_description /home/gino/ROS/lampo_ws_ros2_rolling/install/lampo_description/share/lampo_description
RUN sed --in-place \
      -e 's|^source .*|source "/opt/lampo_ws/install/setup.bash"|' \
      /ros_entrypoint.sh
ENV ROS_DOMAIN_ID ${set__ros_domain_id}