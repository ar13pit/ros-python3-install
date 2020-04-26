#! /usr/bin/env bash

# Add local bin directory to path for pip local executables
if [[ *:$PATH:* != *:$HOME/.local/bin:* ]]
then
    export PATH=$HOME/.local/bin${PATH:+:${PATH}}
fi

# Install dependencies
sudo apt-get install -y -qq python3 python3-dev python3-pip build-essential python3-setuptools python3-wheel > /dev/null
sudo -H pip3 install -U -q pip rosdep wstool
pip3 install --user -U -q pip setuptools
hash -r

pip_packages="rosdep wstool rospkg rosinstall-generator rosinstall vcstools catkin-pkg defusedxml cmake<3.17 backports.ssl_match_hostname twisted"

pip3 install --user -U -q $pip_packages
pip3 install --user -U -q git+https://github.com/catkin/catkin_tools.git
pip3 install --user -U -q -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-18.04 wxPython
pip_packages="$pip_packages wxtools"

sudo rosdep -q init
rosdep -q update

# Setup the base workspace
mkdir -p $HOME/catkin_ws_python3
cd $HOME/catkin_ws_python3

catkin config --init -DCMAKE_BUILD_TYPE=Release -DPYTHON_VERSION=3 --install
rosinstall_generator desktop_full rosbridge_suite --rosdistro melodic --deps --tar > melodic-full.rosinstall
wstool init -j8 src melodic-full.rosinstall > /dev/null

export ROS_PYTHON_VERSION=3
export PYTHONPATH=$HOME/.local/lib/python3.6/site-packages:/usr/lib/python3/dist-packages

# If ros is already installed with python2 support using apt sources, then use the following command to get
# a list of python packages to be installed
#
# rosdep install --simulate --reinstall --from-paths src --ignore-src | grep apt | sed -e "s/.*sudo -H apt-get install //g" | grep -v -E "$(echo "$pip_packages" | sed -e "s/ /|/g" | sed -e "s/_/-/g")" | sed -e "s/^python3\{0,1\}-/python3-/g" | sort | uniq | sed -z "s/\n/ /g"

apt_packages=$(rosdep check --from-paths src --ignore-src | grep apt | sed -e "s/^apt\t//g" | grep -v -E "$(echo "$pip_packages" | sed -e "s/ /|/g" | sed -e "s/_/-/g")" | sed -e "s/^python3\{0,1\}-/python3-/g" | sort | uniq | sed -z "s/\n/ /g")

echo
echo -e "\e[1;97m executing command [sudo -H apt-get install -y -qq --no-install-recommends $apt_packages > /dev/null ]\e[0m"
sudo -H apt-get install -y -qq --no-install-recommends $apt_packages > /dev/null || { echo "Failed to install deps" && exit 1; }

find . -type f -exec sed -i 's/\/usr\/bin\/env[ ]*python/\/usr\/bin\/env python3/g' {} +

# catkin build --no-status rosbridge_suite
catkin build

source install/setup.bash
