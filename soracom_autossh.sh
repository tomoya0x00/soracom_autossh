#!/bin/sh

SSH_INFO_FILE="/var/tmp/ssh_info"
SSH_INFO_FILE_OLD="/var/tmp/ssh_info.old"
SSH_PRIVATEKEY_FILE="/var/tmp/private-key.pem"
AUTOSSH_PIDFILE="/var/run/autossh.pid"

# 自分のIMSIと該当するSSH情報を取得
IMSI=`curl -s http://metadata.soracom.io/v1/subscriber | jq .imsi`
if [ $? -ne 0 ]; then
  echo "failed to get own imsi"
  exit 1
fi

SSH_INFO=`curl -s http://metadata.soracom.io/v1/userdata | jq -r .ssh.imsis[${IMSI}]`
if [ $? -ne 0 ]; then
  echo "failed to get userdata"
  exit 1
fi

# 取得したSSH情報を保存
if [ -e $SSH_INFO_FILE ]; then
  cp -f $SSH_INFO_FILE $SSH_INFO_FILE_OLD
fi

echo $SSH_INFO > $SSH_INFO_FILE

exit_autossh() {
  if [ -e $AUTOSSH_PIDFILE ]; then
    PID=`cat $AUTOSSH_PIDFILE`
    echo "kill autossh pid=$PID"
    kill -9 $PID
    rm $AUTOSSH_PIDFILE
  fi
}

delete_privatekey() {
  if [ -e $SSH_PRIVATEKEY_FILE ]; then
    rm $SSH_PRIVATEKEY_FILE
  fi
}

if [ "$SSH_INFO" != "null" ]; then
  # 自分のSSH情報があれば、前回取得したSSH情報との差分チェック
  if diff -q $SSH_INFO_FILE $SSH_INFO_FILE_OLD > /dev/null 2>&1; then
    # do nothing
    echo "do nothing" 
  else
    # 前回取得したSSH情報との差分があれば、秘密鍵を書き出してautossh開始

    # autosshが起動済みなら終了
    exit_autossh
    delete_privatekey
    
    echo $SSH_INFO | jq -r .privateKey > $SSH_PRIVATEKEY_FILE
    chmod 600 $SSH_PRIVATEKEY_FILE
    AUTOSSH_PIDFILE=$AUTOSSH_PIDFILE \
                   autossh -M 0 -o StrictHostKeyChecking=no \
                   -o UserKnownHostsFile=/dev/null \
                   -o ServerAliveInterval=60 \
                   -o ServerAliveCountMax=3 \
                   -o ExitOnForwardFailure=yes \
                   -i $SSH_PRIVATEKEY_FILE \
                   -N \
                   -f \
                   -R `echo $SSH_INFO | jq -r .portForwardParam` &
    echo "started autossh"
  fi
else
  # 自分のSSH情報が無い場合、autosshが起動済みなら終了
  exit_autossh
  delete_privatekey
fi
