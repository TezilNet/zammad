FROM ruby:3.2.4-slim

# Variables de entorno
ARG DEBIAN_FRONTEND=noninteractive
ARG ZAMMAD_USER=zammad
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV ZAMMAD_DIR=/opt/zammad

# Crear directorio de trabajo
WORKDIR ${ZAMMAD_DIR}

# Instalar Node.js y otras dependencias necesarias
RUN apt-get update && \
    apt-get install -y curl git && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Copiar la aplicación al contenedor
COPY . .

# Ejecutar el setup de Zammad
RUN contrib/docker/setup-cloudrun.sh

# Definir el shell por defecto
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]

# Cambiar el usuario a zammad y configurar el entrypoint
USER zammad:zammad
COPY ${ZAMMAD_DIR}/contrib/docker/cloudrun-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
