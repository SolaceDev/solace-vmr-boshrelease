#!/usr/bin/env bash

# Setup env vars and folders for the ctl script
# This helps keep the ctl script as readable
# as possible

# Usage options:
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh JOB_NAME OUTPUT_LABEL
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar foobar
# source /var/vcap/jobs/foobar/helpers/ctl_setup.sh foobar nginx

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

JOB_NAME=$1
output_label=${1:-JOB_NAME}

export JOB_DIR=/var/vcap/jobs/$JOB_NAME
chmod 755 $JOB_DIR # to access file via symlink

source $JOB_DIR/helpers/ctl_utils.sh
redirect_output ${output_label}

export HOME=${HOME:-/home/vcap}

# Add all packages' /bin & /sbin into $PATH
for package_bin_dir in $(ls -d /var/vcap/packages/*/*bin)
do
  export PATH=${package_bin_dir}:$PATH
done

# Setup log, run and tmp folders
export RUN_DIR=/var/vcap/sys/run/$JOB_NAME
export LOG_DIR=/var/vcap/sys/log/$JOB_NAME
export TMP_DIR=/var/vcap/sys/tmp/$JOB_NAME
export STORE_DIR=/var/vcap/store/$JOB_NAME
for dir in $RUN_DIR $LOG_DIR $TMP_DIR $STORE_DIR
do
  mkdir -p ${dir}
  chown vcap:vcap ${dir}
  chmod 775 ${dir}
done
export TMPDIR=$TMP_DIR

# Setup Core dump pattern for processes running in container
sudo echo "/usr/sw/jail/cores/core.%p" > /proc/sys/kernel/core_pattern

# So we can get cores on the host as well
mkdir -p /usr/sw/jail/
mkdir -p $STORE_DIR/cores
if [ ! -d /usr/sw/jail/cores ]
then
   ln -s $STORE_DIR/cores /usr/sw/jail/cores
fi

# Setup volumes for the VMR Containers on persistent mount point
export VOLUMES_DIR=$STORE_DIR/volumes
export JAIL_DIR=$VOLUMES_DIR/jail
export VAR_DIR=$VOLUMES_DIR/var
export INTERNAL_SPOOL_DIR=$VOLUMES_DIR/internalSpool
export ADB_BACKUP_DIR=$VOLUMES_DIR/adbBackup
export ADB_DIR=$VOLUMES_DIR/adb
for dir in $JAIL_DIR $VAR_DIR $INTERNAL_SPOOL_DIR $ADB_BACKUP_DIR $ADB_DIR
do
  mkdir -p ${dir}
  chown 500:501 ${dir}
  chmod 775 ${dir}
done

PIDFILE=$RUN_DIR/$JOB_NAME.pid