FROM ruby:3.2.4-slim

# Variables de entorno
ARG DEBIAN_FRONTEND=noninteractive
ARG ZAMMAD_USER=zammad
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV ZAMMAD_DIR=/opt/zammad
ENV ZAMMAD_WEBSOCKET_PORT=6042
ENV ZAMMAD_RAILSSERVER_PORT=3000
ENV PORT=${ZAMMAD_RAILSSERVER_PORT}

# Crear directorio de trabajo
WORKDIR ${ZAMMAD_DIR}

# Instalar Node.js y otras dependencias necesarias
RUN apt-get update && \
    apt-get install -y curl git && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

EXPOSE ${ZAMMAD_RAILSSERVER_PORT} ${ZAMMAD_WEBSOCKET_PORT}

# Copiar la aplicación al contenedor
COPY . .

# Ejecutar el setup de Zammad
RUN chmod +x ${ZAMMAD_DIR}/contrib/docker/setup-cloudrun.sh
RUN ${ZAMMAD_DIR}/contrib/docker/setup-cloudrun.sh

# Definir el shell por defecto
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

# Crear el usuario zammad si no existe
RUN useradd -m -d /home/zammad -s /bin/bash zammad

# Cambiar el usuario a zammad y configurar el entrypoint
COPY contrib/docker/cloudrun-entrypoint.sh /entrypoint.sh
RUN chown zammad:zammad /entrypoint.sh
RUN chmod 754 /entrypoint.sh

USER zammad

ENTRYPOINT ["/entrypoint.sh"]
