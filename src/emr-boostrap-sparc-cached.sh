#!/bin/bash
set -x -e

# check for master node
IS_MASTER=false
if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
  IS_MASTER=true
fi

# change a few system parameters
sudo bash -c 'echo "fs.file-max = 25129162" >> /etc/sysctl.conf'
sudo sysctl -p /etc/sysctl.conf
sudo bash -c 'echo "* soft    nofile          1048576" >> /etc/security/limits.conf'
sudo bash -c 'echo "* hard    nofile          1048576" >> /etc/security/limits.conf'
sudo bash -c 'echo "session    required   pam_limits.so" >> /etc/pam.d/su'
  
# move /usr/local and usr/share to /mnt/usr-moved/ to avoid running out of space on /
if [ ! -d /mnt/usr-moved ]; then
  echo "move local start" >> /tmp/install_time.log
  date >> /tmp/install_time.log
  sudo mkdir /mnt/usr-moved
  sudo mv /usr/local /mnt/usr-moved/ && sudo ln -s /mnt/usr-moved/local /usr/
  echo "move local end, move share start" >> /tmp/install_time.log
  date >> /tmp/install_time.log
  sudo mv /usr/share /mnt/usr-moved/ && sudo ln -s /mnt/usr-moved/share /usr/
  echo "move shared end, move home start" >> /tmp/install_time.log
  date >> /tmp/install_time.log
  sudo mv /home /mnt/ && sudo ln -s /mnt/home /home
  echo "move home end" >> /tmp/install_time.log
  date >> /tmp/install_time.log
fi


# only run below on master instance
if [ "$IS_MASTER" = true ]; then

	# copy files needed
	#  1. jupyter-dependencies
	#  2. yum-dependencies
	#  3. sparc

	#cached="s3://sparkAssembler/artifacts/sparc.zip"

	#mkdir /mnt/sparc
	#cd /mnt/sparc
	#aws s3 cp ${cached} sparc.zip
	#unzip sparc.zip
	#rm sparc.zip
	#cd /mnt
	#sudo mv /mnt/sparc /usr/local/share/ 

	# install zstd
	sudo yum install git -y
	git clone https://github.com/facebook/zstd.git
	cd zstd/
	make
	sudo make install
fi

echo "Bootstrap action finished"

