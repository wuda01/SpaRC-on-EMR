#!/bin/bash
set -x -e

# AWS EMR bootstrap script 
NOTEBOOK_DIR="s3://wuda-notebook/notebook"

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


PYTHON3=false
if [ "$PYTHON3" = true ]; then # this will break bigtop/puppet which relies on python 2, so disable with the line above
  export PYSPARK_PYTHON="python3"
  sudo ln -sf /usr/bin/python3.4 /usr/bin/python
  sudo ln -sf /usr/bin/pip-3.4 /usr/bin/pip
else
  sudo python -m pip install --upgrade pip
  sudo python -m pip install jupyter matplotlib seaborn findspark
  sudo ln -sf /usr/local/bin/pip2.7 /usr/bin/pip
fi

sudo python3 -m pip install jupyter
sudo ln -sf /usr/local/bin/ipython /usr/bin/
sudo ln -sf /usr/local/bin/jupyter /usr/bin/ 

sudo python3 -m pip install jupyter matplotlib seaborn findspark

# set the environment
cat << 'EOF' >> ~/.bashrc

export JAVA_HOME="/etc/alternatives/jre"
export HADOOP_HOME_WARN_SUPPRESS="true"
export HADOOP_HOME="/usr/lib/hadoop"
export HADOOP_PREFIX="/usr/lib/hadoop"
export HADOOP_MAPRED_HOME="/usr/lib/hadoop-mapreduce"
export HADOOP_YARN_HOME="/usr/lib/hadoop-yarn"
export HADOOP_COMMON_HOME="/usr/lib/hadoop"
export HADOOP_HDFS_HOME="/usr/lib/hadoop-hdfs"
export HADOOP_CONF_DIR="/usr/lib/hadoop/etc/hadoop"
export YARN_CONF_DIR="/usr/lib/hadoop/etc/hadoop"
export YARN_HOME="/usr/lib/hadoop-yarn"
export HIVE_HOME="/usr/lib/hive"
export HIVE_CONF_DIR="/usr/lib/hive/conf"
export HBASE_HOME="/usr/lib/hbase"
export HBASE_CONF_DIR="/usr/lib/hbase/conf"
export SPARK_HOME="/usr/lib/spark"
export SPARK_CONF_DIR="/usr/lib/spark/conf"
PATH=${PWD}:${PATH}
EOF

source ~/.bashrc

# only run below on master instance
if [ "$IS_MASTER" = true ]; then

	# install zstd
	sudo yum install git -y
	git clone https://github.com/facebook/zstd.git
	cd zstd/
	make
	sudo make install

	# install jupyter and python packages
	export PYSPARK_PYTHON="python3"
	# sudo ln -sf /usr/bin/python3.4 /usr/bin/python
	# sudo ln -sf /usr/bin/pip-3.4 /usr/bin/pip
	# sudo python3 -m pip install jupyter matplotlib seaborn findspark
	# sudo python3 -m pip install pandas numpy
	# sudo python -m pip install jupyter matplotlib seaborn findspark pandas numpy
	# sudo ln -sf /usr/local/bin/ipython /usr/bin/
	# sudo ln -sf /usr/local/bin/jupyter /usr/bin/

	sudo mkdir -p /var/log/jupyter
	mkdir -p ~/.jupyter
	touch ls ~/.jupyter/jupyter_notebook_config.py

	sed -i '/c.NotebookApp.open_browser/d' ~/.jupyter/jupyter_notebook_config.py
	echo "c.NotebookApp.open_browser = False" >> ~/.jupyter/jupyter_notebook_config.py
	sed -i '/c.NotebookApp.token/d' ~/.jupyter/jupyter_notebook_config.py
	echo "c.NotebookApp.token = u''" >> ~/.jupyter/jupyter_notebook_config.py
	echo "c.Authenticator.admin_users = u''" >> ~/.jupyter/jupyter_notebook_config.py
	echo "c.LocalAuthenticator.create_system_users = True" >> ~/.jupyter/jupyter_notebook_config.py
	
	
        if [ ! "$NOTEBOOK_DIR" = "" ]; then

          NOTEBOOK_DIR="${NOTEBOOK_DIR%/}/" # remove trailing / if exists then add /
          if [[ "$NOTEBOOK_DIR" == s3://* ]]; then
            NOTEBOOK_DIR_S3=true
            if [ true = true ]; then
              BUCKET=$(ruby -e "puts '$NOTEBOOK_DIR'.split('//')[1].split('/')[0]")
              FOLDER=$(ruby -e "puts '$NOTEBOOK_DIR'.split('//')[1].split('/')[1..-1].join('/')")
              if [ "$USE_CACHED_DEPS" != true ]; then
                sudo yum install -y automake fuse fuse-devel libxml2-devel git libcurl-devel jsoncpp-devel
              fi
              cd /mnt
              rm -fr s3fs-fuse
              git clone https://github.com/s3fs-fuse/s3fs-fuse.git
              cd s3fs-fuse/
              ls -alrt
              ./autogen.sh
              ./configure
              make
              sudo make install
              sudo su -c 'echo user_allow_other >> /etc/fuse.conf'
              mkdir -p /mnt/s3fs-cache
              mkdir -p /mnt/$BUCKET
              /usr/local/bin/s3fs -o allow_other -o iam_role=auto -o umask=0 -o url=https://s3.amazonaws.com  -o no_check_certificate -o enable_noobj_cache -o use_cache=/mnt/s3fs-cache $BUCKET /mnt/$BUCKET
              echo "c.NotebookApp.notebook_dir = '/mnt/$BUCKET/$FOLDER'" >> ~/.jupyter/jupyter_notebook_config.py
              echo "c.ContentsManager.checkpoints_kwargs = {'root_dir': '.checkpoints'}" >> ~/.jupyter/jupyter_notebook_config.py
            fi
          else
            echo "c.NotebookApp.notebook_dir = '$NOTEBOOK_DIR'" >> ~/.jupyter/jupyter_notebook_config.py
            echo "c.ContentsManager.checkpoints_kwargs = {'root_dir': '.checkpoints'}" >> ~/.jupyter/jupyter_notebook_config.py
          fi
        fi


	# install default kernels
	sudo python3 -m pip install notebook ipykernel
	sudo python3 -m ipykernel install
	sudo python -m pip install notebook ipykernel
	sudo python -m ipykernel install
	sudo python3 -m pip install metakernel
	sudo python3 -m pip install bash_kernel
	sudo python3 -m bash_kernel.install

	# install spark kernel using toree
	# sudo python3 -m pip install --upgrade toree
	# sudo jupyter toree install --spark_home=$SPARK_HOME # will install scala
	# jupyter toree install --spark_home=$SPARK_HOME --interpreters=PySpark --user

fi

echo "Bootstrap action finished"

