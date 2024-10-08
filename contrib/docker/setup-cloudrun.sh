#!/usr/bin/env bash
set -e

# Paquetes necesarios para la compilación y la configuración
PACKAGES="build-essential curl git libimlib2-dev libpq-dev shared-mime-info postgresql"

# Actualizar e instalar dependencias necesarias
apt-get update && \
apt-get upgrade -y && \
apt-get install -y --no-install-recommends ${PACKAGES}

/etc/init.d/postgresql start
su - postgres bash -c "createuser zammad -R -S"
su - postgres bash -c "createdb --encoding=utf8 --owner=zammad zammad"

# Cambiar al directorio de la aplicación
cd "${ZAMMAD_DIR}"

# Configurar Bundler para evitar las dependencias innecesarias y luego instalar las necesarias
bundle config set --local without 'test development mysql'
bundle config set --local frozen 'true'
bundle install
# bundle install --clean

# Precompilar los assets (sin necesidad de Redis)
touch db/schema.rb
ZAMMAD_SAFE_MODE=1 DATABASE_URL=postgresql://zammad:/zammad bundle exec rake assets:precompile

# Limpiar archivos temporales y dependencias innecesarias
rm -r tmp/*
script/build/cleanup.sh

/etc/init.d/postgresql stop


# Limpiar listas de paquetes de apt para reducir el tamaño de la imagen
apt-get remove -y build-essential git curl postgresql && \
apt-get autoremove -y && \
apt-get clean && \
rm -rf /tmp/* /var/tmp/*

# apt-get clean && \
# rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

