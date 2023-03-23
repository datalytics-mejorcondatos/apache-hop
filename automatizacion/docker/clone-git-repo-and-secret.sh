#!/bin/bash
cd /home/hop
git clone ${GIT_REPO_URI}

cd /home/hop/${HOP_PROJECT_NAME}
# git clone ${GIT_REPO_CONFIG_URI}
mkdir config

# CONFIG_FILE es una variable de entorno que setea AWS Batch con el valor de un secret de Secrets Manager
echo "$CONFIG_FILE" > "/home/hop/${HOP_PROJECT_NAME}/config/env-config.json"

chown -R hop:hop /home/hop/${HOP_PROJECT_NAME}