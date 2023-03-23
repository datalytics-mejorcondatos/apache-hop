FROM apache/hop:2.3.0
ENV GIT_REPO_URI=
# ejemplo: https://github.com/datalytics-mejorcondatos/apache-hop.git

USER root
RUN apk update \
  && apk add --no-cache git
  
# Copia script para usar con HOP_CUSTOM_ENTRYPOINT_EXTENSION_SHELL_FILE_PATH, es lo primero que ejecuta el contenedor.
COPY --chown=hop:hop ./clone-git-repo.sh /home/hop/clone-git-repo.sh

USER hop