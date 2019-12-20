#!/bin/bash
set -e

# This file will be executed after intializing the database.
MYSQL_SQL_FILE=/tmp/schema.sql

mkdir /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

mysqld &
pid="$!"

for i in {30..0}; do
        if echo 'SELECT 1' | mysql &> /dev/null; then
                break
        fi
        echo 'MySQL init process in progress...'
        sleep 1
done
if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.'
        exit 1
fi

echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | mysql

echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" | mysql
echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" | mysql
echo 'FLUSH PRIVILEGES ;' | mysql

echo Running $MYSQL_SQL_FILE
mysql $MYSQL_DATABASE < "$MYSQL_SQL_FILE"

if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo >&2 'MySQL init process failed.'
        exit 1
fi

# listen all ips
sed -i 's/^ *bind-address\s*=.*$/bind-address=0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

echo MySQL init process done. Ready for start up.