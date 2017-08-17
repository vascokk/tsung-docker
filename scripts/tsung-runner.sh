#!/bin/sh

# Utility to run tsung and automatically generate reports

# make sure SSHD is started in order to connect to other tsung agents
service ssh start
# /etc/init.d/ssh start
# /etc/init.d/cron start


# start crontab to update tsung hosts found in the cluster
echo ${MARATHON_URL} > /etc/tsung/marathon_url
crontab /etc/crontab
service cron start


slave=$(echo $SLAVE)
if [ -n "${slave}" ]; then
    echo "Running in SLAVE mode ..."
    tail -f /var/log/tsung/tsung-update-hosts.log
    exit
fi

# http://stackoverflow.com/questions/2369341/which-tcp-port-does-erlang-use-for-connecting-to-a-remote-node
# erl -kernel inet_dist_listen_min 9001 inet_dist_listen_max 9005

current_date=$(date +%Y%m%d-%H%M)
echo "Tsung log directory should be ${current_date}"

start_stats()
{
    sleep 5

    cp /usr/lib/tsung/bin/tsung_stats.pl /usr/local/tsung/${current_date}/
    chmod a+x /usr/local/tsung/${current_date}/tsung_stats.pl

    cd /usr/local/tsung/${current_date}/
    rm -f index.html

    while :
    do
        ./tsung_stats.pl
        sleep 5
    done

}

start_stats &

cmd="tsung -l /usr/local/tsung/ "$@" start"
echo "Executin ${cmd} ..."
# ${cmd}
exec $cmd
