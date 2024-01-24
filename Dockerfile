FROM navigation2:rolling AS dependencies

ARG set__gz_version=harmonic

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
                                          ros-rolling-topic-based-ros2-control\
                                          xterm

#--------------------------------------------------------------------------------
FROM dependencies AS setup

WORKDIR /opt
RUN mkdir -p lampo_ws/src
WORKDIR /opt/lampo_ws/src
COPY ./src .
RUN git clone https://github.com/ros-controls/gz_ros2_control\
    && git clone https://github.com/ros-controls/ros2_control && cd ros2_control && git checkout 4.3.0
RUN git clone https://github.com/ros-controls/ros2_controllers.git && cd ros2_controllers && git checkout 4.4.0
RUN git clone https://github.com/gazebosim/ros_gz.git -b iron
RUN git clone https://github.com/ros-controls/kinematics_interface.git && cd kinematics_interface && git checkout 1.0.0
RUN git clone https://github.com/ros-controls/control_msgs.git
RUN git clone https://github.com/ros-drivers/ackermann_msgs.git && cd ackermann_msgs && git checkout ros2

WORKDIR /opt/lampo_ws

#--------------------------------------------------------------------------------
FROM setup AS build

ARG set__ros_domain_id=15
ARG set__home_dir=stefanomutti

RUN . /opt/overlay_ws/install/setup.sh && colcon build --symlink-install --cmake-args -DCMAKE_CXX_FLAGS="-w"
RUN mkdir -p /home/${set__home_dir}/.gz/fuel
COPY ./fuel /home/${set__home_dir}/.gz/fuel
RUN mkdir -p /home/${set__home_dir}/lampo_ws/install/ur_description/share/ \
    && cp -r /opt/ros/rolling/share/ur_description /home/${set__home_dir}/lampo_ws/install/ur_description/share/
RUN mkdir -p /home/${set__home_dir}/lampo_ws/install/lampo_description/share/ \
    && ln -s /opt/lampo_ws/install/lampo_description/share/lampo_description /home/${set__home_dir}/lampo_ws/install/lampo_description/share/lampo_description
RUN sed --in-place \
      -e 's|^source .*|source "/opt/lampo_ws/install/setup.bash"|' \
      /ros_entrypoint.sh
ENV ROS_DOMAIN_ID ${set__ros_domain_id}

CMD ["echo","rocker","--x11","--volume","fuel:/home/stefanomutti/.gz/fuel:ro", "", "--", "lampo", "/bin/bash"]