if mdata-get redis_master_host 1>/dev/null 2>&1; then
  REDIS_MASTER_HOST=`mdata-get redis_master_host`
  
  if mdata-get redis_tls_port 1>/dev/null 2>&1; then
    REDIS_PORT=`mdata-get redis_tls_port`
    sed -i "s/-p 6379/-p ${REDIS_PORT}/" \
        /opt/local/etc/zabbix_agentd.conf.d/redis.conf
  else
    REDIS_PORT="6379"
  fi
  
  if [[ $REDIS_MASTER_HOST != "127.0.0.1" ]]; then
    sed -i "s/# slaveof <masterip> <masterport>/slaveof ${REDIS_MASTER_HOST} ${REDIS_PORT}/" \
        /opt/local/etc/redis.conf
    sed -i "s/127.0.0.1/${REDIS_MASTER_HOST}/" \
        /opt/local/etc/sentinel.conf
  fi
fi

if mdata-get redis_master_name 1>/dev/null 2>&1; then
  REDIS_MASTER_NAME=`mdata-get redis_master_name`
  sed -i "s/redis_master/${REDIS_MASTER_NAME}/g" \
      /opt/local/etc/sentinel.conf
fi

if mdata-get redis_master_pwd 1>/dev/null 2>&1; then
  REDIS_MASTER_PWD=`mdata-get redis_master_pwd`
  sed -i "s/# requirepass foobared/requirepass ${REDIS_MASTER_PWD}/" \
      /opt/local/etc/redis.conf
  sed -i "s/securepwd/${REDIS_MASTER_PWD}/" \
      /opt/local/etc/sentinel.conf
  sed -i "s/-a securepwd/-a ${REDIS_MASTER_PWD}/" \
      /opt/local/etc/zabbix_agentd.conf.d/redis.conf
  # ensure onyl root and zabbix can read this file
  chown root:zabbix /opt/local/etc/zabbix_agentd.conf.d/redis.conf
  chmod 0640 /opt/local/etc/zabbix_agentd.conf.d/redis.conf
else
  sed -i "s/sentinel auth-pass redis_master securepwd//" \
      /opt/local/etc/sentinel.conf
  sed -i "s/# requirepass foobared/requirepass ${REDIS_MASTER_PWD}/" \
      /opt/local/etc/redis.conf
  sed -i "s/-a securepwd//" \
      /opt/local/etc/zabbix_agentd.conf.d/redis.conf
fi

if mdata-get redis_tls_port 1>/dev/null 2>&1; then
  REDIS_TLS_PORT=`mdata-get redis_tls_port`
  cat >> /opt/local/etc/redis.conf << EOF
# tls support
tls-port ${REDIS_TLS_PORT}
tls-replication
EOF
else
  cat >> /opt/local/etc/redis.conf << EOF
# to enable tls support remove comments
# tls-port 6380
# tls-replication
EOF
fi

gsed -i \
     -e "s/bind 127.0.0.1/bind 0.0.0.0/" \
     -e "s/protected-mode yes/protected-mode no" \
     -e "s/# maxmemory <bytes>/maxmemory 1gb/" \
     -e "s/# maxmemory-policy noeviction/# maxmemory-policy allkeys-lfu/" \
     -e "s/# unixsocket \/tmp\/redis.sock/unixsocket \/var\/tmp\/redis.sock/" \
     /opt/local/etc/redis.conf

cat >> /opt/local/etc/redis.conf << EOF

# prevent usage of these commands for security reasons
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command CONFIG ""
rename-command SWAPDB ""
EOF

touch /var/log/redis/redis.log
chown redis:redis /var/log/redis/redis.log

svcadm enable svc:/pkgsrc/redis:default
