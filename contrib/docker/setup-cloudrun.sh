#!/usr/bin/env bash
set -e

# Paquetes necesarios para la compilación y la configuración
# PACKAGES="build-essential curl git libimlib2-dev libpq-dev shared-mime-info postgresql"
PACKAGES="build-essential curl git libimlib2-dev libpq-dev shared-mime-info"

# Actualizar e instalar dependencias necesarias
apt-get update && \
apt-get upgrade -y && \
apt-get install -y --no-install-recommends ${PACKAGES}

# Cambiar al directorio de la aplicación
cd "${ZAMMAD_DIR}"

# Configurar Bundler para evitar las dependencias innecesarias y luego instalar las necesarias
bundle config set --local without 'test development mysql'
bundle config set --local frozen 'true'
bundle install
# bundle install --clean

# Precompilar los assets (sin necesidad de Redis)
touch db/schema.rb
ZAMMAD_SAFE_MODE=1 bundle exec rake assets:precompile

# Limpiar archivos temporales y dependencias innecesarias
# rm -r tmp/*
# script/build/cleanup.sh

# Limpiar listas de paquetes de apt para reducir el tamaño de la imagen
apt-get remove -y build-essential git curl && \
apt-get autoremove -y && \
apt-get clean
# apt-get clean && \
# rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
rm -rf /tmp/* /var/tmp/*
