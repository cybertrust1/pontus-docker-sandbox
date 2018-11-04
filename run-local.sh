#!/bin/bash
docker run --privileged --name pontus_sandbox-6 -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p5006:5006 -p5007:5007 --dns 127.0.0.1 --dns-search pontusvision.com -p5005:5005 -p8443:8443 -p18443:8443 --hostname=pontus-sandbox.pontusvision.com -d  pontusvisiongdpr/open-source-gdpr2

