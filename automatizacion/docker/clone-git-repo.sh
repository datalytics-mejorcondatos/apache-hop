#!/bin/bash
cd /home/hop
git clone ${GIT_REPO_URI}

chown -R hop:hop /home/hop/${HOP_PROJECT_NAME}