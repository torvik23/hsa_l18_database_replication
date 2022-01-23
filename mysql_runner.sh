#!/bin/bash
BASE_PATH=$(dirname $0)


echo "+---------Waiting for MySQL containers to start"
until mysql --host mysql_master -uroot -p$MYSQL_ROOT_PASSWORD
do
    echo "Waiting for mysql_slave2 database connection..."
    sleep 4
done

echo "+---------Create replication user on MASTER"
mysql --host mysql_master -uroot -p$MYSQL_ROOT_PASSWORD -AN -e "CREATE USER '$MYSQL_REPLICATION_USER'@'%';"
mysql --host mysql_master -uroot -p$MYSQL_ROOT_PASSWORD -AN -e "GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_REPLICATION_USER'@'%' IDENTIFIED BY '$MYSQL_REPLICATION_PASSWORD';"
mysql --host mysql_master -uroot -p$MYSQL_ROOT_PASSWORD -AN -e 'FLUSH PRIVILEGES;'

until mysql --host mysql_slave1 -uroot -p$MYSQL_ROOT_PASSWORD
do
    echo "Waiting for mysql_slave1 database connection..."
    sleep 4
done

echo "+---------STOP and RESET SLAVE#1"
mysql --host mysql_slave1 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e 'STOP SLAVE;';
mysql --host mysql_slave1 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e 'RESET SLAVE ALL;';

until mysql --host mysql_slave2 -uroot -p$MYSQL_ROOT_PASSWORD
do
    echo "Waiting for mysql_slave2 database connection..."
    sleep 4
done

echo "+---------STOP and RESET SLAVE#2"
mysql --host mysql_slave2 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e 'STOP SLAVE;';
mysql --host mysql_slave2 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e 'RESET SLAVE ALL;';

echo "============== Check MASTER configuration ================"
MASTER_POSITION=$(eval "mysql --host mysql_master -uroot -p$MYSQL_ROOT_PASSWORD -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
MASTER_FILE=$(eval "mysql --host mysql_master -uroot -p$MYSQL_ROOT_PASSWORD -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")
MASTER_IP=$(eval "getent hosts mysql_master|awk '{print \$1}'")

echo $MASTER_IP

echo "============== Starting replica on SLAVE#1 ================"
mysql --host mysql_slave1 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e "CHANGE MASTER TO MASTER_HOST='mysql_master', \
        MASTER_USER='$MYSQL_REPLICATION_USER', MASTER_PASSWORD='$MYSQL_REPLICATION_PASSWORD', MASTER_LOG_FILE='$MASTER_FILE', \
        master_log_pos=$MASTER_POSITION;"
mysql --host mysql_slave1 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e "START SLAVE;"

echo "============== Starting replica on SLAVE#2 ================"
mysql --host mysql_slave2 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e "CHANGE MASTER TO MASTER_HOST='mysql_master', \
        MASTER_USER='$MYSQL_REPLICATION_USER', MASTER_PASSWORD='$MYSQL_REPLICATION_PASSWORD', MASTER_LOG_FILE='$MASTER_FILE', \
        master_log_pos=$MASTER_POSITION;"
mysql --host mysql_slave2 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e "START SLAVE;"

echo "Increase the max_connections to 2000"
mysql --host mysql_master -uroot -p$MYSQL_ROOT_PASSWORD -AN -e 'set GLOBAL max_connections=2000';
mysql --host mysql_slave1 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e 'set GLOBAL max_connections=2000';
mysql --host mysql_slave2 -uroot -p$MYSQL_ROOT_PASSWORD -AN -e 'set GLOBAL max_connections=2000';

echo "Show SLAVE#1 status"
mysql --host mysql_slave1 -uroot -p$MYSQL_ROOT_PASSWORD -e "SHOW SLAVE STATUS \G"
echo "Show SLAVE#2 status"
mysql --host mysql_slave2 -uroot -p$MYSQL_ROOT_PASSWORD -e "SHOW SLAVE STATUS \G"

echo "--------------------"
echo "MySQL servers created!"
