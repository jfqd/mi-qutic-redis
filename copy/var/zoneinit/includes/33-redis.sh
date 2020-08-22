if mdata-get redis_master_host 1>/dev/null 2>&1; then
  REDIS_MASTER_HOST=`mdata-get redis_master_host`
  
  if mdata-get redis_tls_port 1>/dev/null 2>&1; then
    REDIS_PORT=`mdata-get redis_tls_port`
    sed -i "s/-p 6379/-p ${REDIS_PORT}/" \
        /opt/local/etc/zabbix_agentd.conf.d/redis.conf
  else
    REDIS_PORT="6379"
  fi

  ACTIVE_IP=$(ifconfig net0 | grep 'inet '  | awk '{print $2}' | tr -d '\n')
  if [[ $REDIS_MASTER_HOST != "${ACTIVE_IP}" ]]; then
    sed -i "s/# replicaof <masterip> <masterport>/replicaof ${REDIS_MASTER_HOST} ${REDIS_PORT}/" \
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
  sed -e \
      -i "s/# requirepass foobared/requirepass ${REDIS_MASTER_PWD}/" \
      -i "s/# masterauth <master-password>/masterauth {REDIS_MASTER_PWD}/" \
      /opt/local/etc/redis.conf
  sed -i "s/securepwd/${REDIS_MASTER_PWD}/" \
      /opt/local/etc/sentinel.conf
  sed -i "s/-a securepwd/-a ${REDIS_MASTER_PWD}/" \
      /opt/local/etc/zabbix_agentd.conf.d/redis.conf
  # ensure onyl root and zabbix can read this file
  chown root:zabbix /opt/local/etc/zabbix_agentd.conf.d/redis.conf
  chmod 0640 /opt/local/etc/zabbix_agentd.conf.d/redis.conf
  # redis-cli
  echo "export REDISCLI_AUTH=${REDIS_MASTER_PWD}" >> /root/.bashrc
  chmod 0640 /root/.bashrc
else
  sed -i "s/sentinel auth-pass redis_master securepwd//" \
      /opt/local/etc/sentinel.conf
  sed -i "s/# requirepass foobared/requirepass ${REDIS_MASTER_PWD}/" \
      /opt/local/etc/redis.conf
  sed -i "s/-a securepwd//" \
      /opt/local/etc/zabbix_agentd.conf.d/redis.conf
  cat >> /opt/local/etc/redis.conf << EOF

# prevent usage of these commands for security reasons
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command CONFIG ""
rename-command SWAPDB ""
EOF
fi

if mdata-get redis_tls_port 1>/dev/null 2>&1; then
  REDIS_TLS_PORT=`mdata-get redis_tls_port`
  gsed -i \
       -e "s/# tls-port 6379/tls-port ${REDIS_TLS_PORT}/" \
       -e "s|# tls-cert-file redis.crt|tls-cert-file /opt/local/etc/tls/redis.crt|" \
       -e "s|# tls-key-file redis.key|tls-key-file /opt/local/etc/tls/redis.key|" \
       -e "s|# tls-ca-cert-file ca.crt|tls-ca-cert-file /etc/ssl/certs/ca-certificates.crt|" \
       -e "s/# tls-auth-clients no/tls-auth-clients no/" \
       -e "s/# tls-replication yes/tls-replication yes/" \
       -e "s/# tls-ciphers DEFAULT:!MEDIUM/tls-ciphers DEFAULT:!MEDIUM/" \
       -e "s/# tls-protocols \"TLSv1.2 TLSv1.3\"/tls-protocols \"TLSv1.2 TLSv1.3\"/" \
       -e "s/# tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256/tls-ciphersuites TLS_CHACHA20_POLY1305_SHA256/" \
       -e "s/# tls-prefer-server-ciphers yes/tls-prefer-server-ciphers yes/" \
       /opt/local/etc/redis.conf
  gsed -i \
       -e "s|# tls-cert-file /opt/local/etc/tls/redis.crt|tls-cert-file /opt/local/etc/tls/redis.crt|" \
       -e "s|# tls-key-file /opt/local/etc/tls/redis.key|tls-key-file /opt/local/etc/tls/redis.key|" \
       -e "s|# tls-ca-cert-file /etc/ssl/certs/ca-certificates.crt|tls-ca-cert-file /etc/ssl/certs/ca-certificates.crt|" \
       -e "s|# tls-auth-clients no|tls-auth-clients no|" \
       -e "s|# tls-replication yes|tls-replication yes|" \
       -e "s|# tls-port 26379|tls-port 26379|" \
       -e "s|# port 0|port 0|" \
       /opt/local/etc/sentinel.conf
fi

gsed -i \
     -e "s/bind 127.0.0.1/bind 0.0.0.0/" \
     -e "s/protected-mode yes/protected-mode no/" \
     -e "s/# maxmemory <bytes>/maxmemory 1gb/" \
     -e "s/# maxmemory-policy noeviction/# maxmemory-policy allkeys-lfu/" \
     -e "s/# unixsocket \/tmp\/redis.sock/# unixsocket \/var\/tmp\/redis.sock/" \
     /opt/local/etc/redis.conf

touch /var/log/redis/redis.log
chown redis:redis /var/log/redis/redis.log

# enable redis
svcadm enable svc:/pkgsrc/redis:default

# enable sentinel
svcadm enable redis/sentinel
ln -nfs /var/svc/log/redis-sentinel:default.log /var/log/redis/sentinel_log
