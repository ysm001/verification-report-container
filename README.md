## Dockerfile for Verification Report

### build
```
sh build.sh centos:centos6
docker build -t <container-name> .
```

### run
```
docker run -p 127.0.0.1:3000 -v <log-path>:/var/log <container-name>
```

### info
- port: 3000
- log path: /var/log
- db path: /data/db
