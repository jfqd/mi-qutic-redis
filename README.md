# mi-qutic-redis

SmartOS image for redis with sentinel support

## Useful sentinel commands

```
redis-cli --tls -p 26379 SENTINEL masters
redis-cli --tls -p 26379 SENTINEL replicas mymaster
redis-cli --tls -p 26379 SENTINEL sentinels mymaster
```

## Redis sentinel documentation

https://redis.io/topics/sentinel

## Redis tls documentation

https://redis.io/topics/encryption

(c) 2020 S. Husch | qutic development GmbH