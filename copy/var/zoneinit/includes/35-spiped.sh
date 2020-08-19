# if mdata-get redis_master_host 1>/dev/null 2>&1; then
#   REDIS_MASTER_HOST=`mdata-get redis_master_host`
#   sed -i "s/-t 127.0.0.1:26379/-t $REDIS_MASTER_HOST:26379/g" /opt/local/lib/svc/manifest/spiped-redis-replication.xml
#   svccfg import /opt/local/lib/svc/manifest/spiped-redis-replication.xml
#   sed -i "s/# slaveof <masterip> <masterport>/slaveof 127.0.0.1 16379/g" nano /opt/local/etc/redis.conf
# fi
# svcadm enable svc:/pkgsrc/redis:default
#
# if mdata-get mysql_replication_host 1>/dev/null 2>&1; then
#   MYSQL_MASTER_HOST=`mdata-get mysql_replication_host`
#   sed -i "s/-t 127.0.0.1:23306/-t $MYSQL_MASTER_HOST:23306/g" /opt/local/lib/svc/manifest/spiped-percona-replication.xml
#   svccfg import /opt/local/lib/svc/manifest/spiped-percona-replication.xml
# fi
