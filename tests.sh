#! /bin/bash
#set -x
#for i in {1..6}; do echo "running"; done
for i in {1..6}; do curl http://localhost:8000/v1/healthcheck; done
