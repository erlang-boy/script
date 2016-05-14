#!/bin/sh
## @author:  Long Huaqiao
## @copyright longhq@expert-db.com
## @doc:     The config envrionment for titan-server
## ------------------------------------------------------------------
##
## The ENV for config system init
##   sym_env interface for get this envrionment:
##       os:getenv("SERVER_ROOT").
##       os:getenv("CODE_ROOT").
##       os:getenv("OTP_ROOT").
##       os:getenv("PRIVATE_DIR").
##
##       os:getenv("DEV_PATCHES_DIR").
##       os:getenv("LOG_DIR").
##       os:getenv("DATA_DIR").
##       os:getenv("RELEASES_DIR").
##       os:getenv("DATA_BAK").
##
## ------------------------------------------------------------------

export SYSTEM_DEFAULT_CONF=TITAN_SRV

error() {
    ### error String Code
    echo "$SCRIPT, ERROR:" $1 >&2
    exit $2
}

unpack_pkg() {
    local dest=${1:?"Please input code root path."}
    if [ -s $dest/titan-servers-*.tar.gz ]; then
        echo "unpacking servers pkg in $dest"
        (cd $dest; tar xfz titan-servers-*.tar.gz)
        sync :> $dest/titan-servers-*.tar.gz
    fi
}

unpack_otp() {
    local dest=${1:?"Please input otp root path."}
    local otp_root=$(echo ${dest}/*_otp/otp-*/priv/pkg)

    if [ -s $otp_root/otp-*.tar.gz ]; then
        echo "unpacking OTP in $otp_root"
        (cd $otp_root; tar xfz otp-*.tar.gz)
        sync :> $otp_root/otp-*.tar.gz
    fi
}

### -----------Starting set envrionment for titan_server-------------
if [ -z "$dev_flag" ]; then

    echo "Starting Produce mode server..."

    [ -z "$srv_id" ] || [ -z "$ps_number" ] && \
    echo "'-id (1|2)', '-n (1|2|n)' are mandatory option" && help

	[ -z "$srv_role" ] && echo "'-r' is mandatory option, must be specified start task \
role for server node, e.g: -r (sh_node|dh_node|om_node)" && help

else

	echo "Starting Development mode server..."

fi

### -------------------Defined default start path--------------------

## Defined default path name
APP_NAME=titan-server
SERVER_ROOT_NAME=titan_root
CODE_ROOT_NAME=titan_server
DATA_ROOT_NAME=titan_data
DATA_BAK_ROOT_NAME=titan_backup

## Check DATA dir if already exists
if [ -d /data ]; then
    mkdir -p /data/servers && ROOT_HOME=/data/servers
else
    ROOT_HOME=$HOME
fi

## Defined default SERVER_ROOT dir
export SERVER_ROOT=${SERVER_ROOT:-${ROOT_HOME}/$SERVER_ROOT_NAME}

## Defined default NODE_ROOT dir
export CODE_ROOT=${CODE_ROOT:-${SERVER_ROOT}/$CODE_ROOT_NAME}
export DEV_PATCHES_DIR=${DEV_PATCHES_DIR:-${HOME}/${APP_NAME}/dev_patches}

## Defined default DATA_ROOT dir
export DATA_ROOT=${DATA_ROOT:-${ROOT_HOME}/$DATA_ROOT_NAME}
export DATA_BAK_ROOT=${DATA_BAK_ROOT:-${ROOT_HOME}/$DATA_BAK_ROOT_NAME}

### -----------------------------------------------------------------

## Creating the SERVER_ROOT, if it doesn't already exists
if [ -d $SERVER_ROOT ] && [ -n "$dev_flag" ] && [ -z "$ds_keep" ] && \
[ -z "$half_prod_flag" ]; then
    echo "Creating SERVER_ROOT already exists, so remove old source."
    rm -rf $SERVER_ROOT/ $SERVER_ROOT
fi

mkdir -p $SERVER_ROOT || error "Failed to create SERVER_ROOT: $SERVER_ROOT" 1
mkdir -p $CODE_ROOT || error "Failed to create CODE_ROOT: $CODE_ROOT" 1

## Creating the DEV_PATCHES_DIR, if it doesn't already exists
if [ -d $DEV_PATCHES_DIR ] && [ -n "$dev_flag" ] && [ -z "$ds_keep" ] && \
[ -z "$half_prod_flag" ]; then
    echo "Creating DEV_PATCHES_DIR already exists, so remove old source."
    rm -rf $DEV_PATCHES_DIR
fi

mkdir -p $DATA_ROOT || error "Failed to create DATA_ROOT: $DATA_ROOT" 1
mkdir -p $DATA_BAK_ROOT || error "Failed to create DATA_BAK_ROOT: $DATA_BAK_ROOT" 1

### -----------------------------------------------------------------
## Create symlink for SERVER_ROOT and NODE_ROOT
## ln -snf $DATA_BAK_ROOT ${HOME}/$DATA_BAK_ROOT_NAME
### -----------------------------------------------------------------
ln -snf $SERVER_ROOT ${HOME}/$SERVER_ROOT_NAME
ln -snf $DATA_ROOT ${HOME}/$DATA_ROOT_NAME
ln -snf $DATA_BAK_ROOT ${HOME}/$DATA_BAK_ROOT_NAME

### -----------------------------------------------------------------
### This is download interface, download release titan-servers package.
### if produce environment, first download package in the target server
### -----------------------------------------------------------------

if [ -z "$ds_keep" ]; then
    export RELEASE_PATH=${RELEASE_PATH:-`dirname $SCRIPT_DIR`}

    cp -Rf $RELEASE_PATH/titan-servers-*.*.*.tar.gz $CODE_ROOT
    ln -sF $RELEASE_PATH/bin $CODE_ROOT
    ln -sF $RELEASE_PATH/etc $CODE_ROOT

    unpack_pkg $CODE_ROOT
fi

### -----------------------------------------------------------------

unpack_otp $CODE_ROOT

export OTP_ROOT=`ls -d $CODE_ROOT/*_otp/otp-*/priv/pkg`

## first OTP_ROOT, because ignore other system default otp erl
export PATH=${OTP_ROOT:?}/bin:$PATH

export ERL_CALL=$OTP_ROOT/lib/erl_interface-*/bin/erl_call
export HEART_COMMAND=${HEART_COMMAND:-"/usr/bin/sudo /sbin/reboot -f"}
export EXTRA_START_FLAGS="-os_mon disk_almost_full_threshold 0.95"

## For run_erl used
export RUN_ERL_LOG_GENERATIONS=10
export RUN_ERL_LOG_MAXSIZE=2000000
