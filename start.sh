#!/bin/sh

SCRIPTPATH=/usr/games/minecraft
SERVER=server.py
CONSOLE=mineos_console.py
CONFIGFILE=/usr/games/minecraft/mineos.conf
DATAPATH=/var/games/minecraft
USER=minecraft
GROUP=minecraft

# Create dooes not exists directories
chown $USER:$GROUP $DATAPATH
if [ ! -d $DATAPATH/ssl_certs ]; then
    /usr/bin/sudo -u $USER /usr/bin/mkdir $DATAPATH/ssl_certs
fi
if [ ! -d $DATAPATH/log ]; then
    /usr/bin/sudo -u $USER /usr/bin/mkdir $DATAPATH/log
fi
if [ ! -d $DATAPATH/run ]; then
    /usr/bin/sudo -u $USER /usr/bin/mkdir $DATAPATH/run
fi

# Changing password
if [ ! -f $SCRIPTPATH/.initialized ]; then
    if [ "$PASSWORD" = "" ]; then
        PASSWORD=`pwgen 10 1`
        echo "Login password is \"$PASSWORD\""
    fi
    echo "$USER:$PASSWORD" | chpasswd
    /usr/bin/sudo -u $USER /usr/bin/touch $SCRIPTPATH/.initialized
fi

# Generate ssl certrificates
CERT_DIR=$DATAPATH/ssl_certs
if [ ! -f "$CERT_DIR/mineos.pem" ]; then
    /usr/bin/sudo -u $USER CERTFILE=$CERT_DIR/mineos.pem CRTFILE=$CERT_DIR/mineos.crt KEYFILE=$CERT_DIR/mineos.key ./generate-sslcert.sh
fi

# Starting minecraft servers
/usr/bin/sudo -u $USER /usr/bin/python $SCRIPTPATH/$CONSOLE -d $DATAPATH restore
/usr/bin/sudo -u $USER /usr/bin/python $SCRIPTPATH/$CONSOLE -d $DATAPATH start

# Trap function
_trap() {
    kill $PID

    # Wait for shutdown
    ALIVE=1
    while [ $ALIVE != 0 ]; do
        ALIVE=`pgrep $PID | wc -l`
        /usr/bin/sleep 1
    done

    /usr/bin/sudo -u $USER /user/bin/python $SCRIPTPATH/$CONSOLE -d $DATAPATH stop
}
trap '_trap' 15

# Starting Supervisor
supervisord -c /etc/supervisor/supervisord.conf & PID=$!

wait $PID
