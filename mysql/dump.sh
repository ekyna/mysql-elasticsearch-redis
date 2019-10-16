#!/usr/bin/env bash

MS_TMP_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

echo "[client]
user = $1
password = $2" > /etc/mysql/conf.d/${MS_TMP_ID}.login.cnf

mysqldump \
    --defaults-file=/etc/mysql/conf.d/${MS_TMP_ID}.login.cnf \
    --skip-comments \
    --net_buffer_length=4096 \
    --default-character-set=utf8 \
    $3 >> /dev/stdout

rm /etc/mysql/conf.d/${MS_TMP_ID}.login.cnf

exit 0
