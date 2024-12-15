#!/bin/bash

# Actualizar el sistema
apt update && apt upgrade -y

# Instalar dependencias básicas
apt install -y curl wget git ca-certificates gnupg lsb-release software-properties-common unzip

# Instalar Docker
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    wget -qO- https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt update && apt install -y docker-ce docker-ce-cli containerd.io
else
    echo "Docker ya está instalado."
fi

# Habilitar e iniciar Docker
systemctl enable docker
systemctl start docker

# Instalar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    wget -qO /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/$(wget -qO- https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '\"' -f 4)/docker-compose-$(uname -s)-$(uname -m)"
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose ya está instalado."
fi

# Eliminar instalaciones previas de Supabase
if [ -d "/opt/supabase" ]; then
    echo "Eliminando instalación previa de Supabase..."
    rm -rf /opt/supabase
fi

# Clonar el repositorio de Supabase
mkdir -p /opt/supabase
cd /opt/supabase
git clone --depth 1 https://github.com/supabase/supabase.git .

# Generar variables de entorno
POSTGRES_PASSWORD=$(openssl rand -hex 16)
JWT_SECRET=$(openssl rand -hex 32)
ANON_KEY=$(openssl rand -hex 32)
SERVICE_ROLE_KEY=$(openssl rand -hex 32)

cat <<EOF > .env
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=supabase
POSTGRES_PORT=5432
POSTGRES_HOST=db
JWT_SECRET=$JWT_SECRET
ANON_KEY=$ANON_KEY
SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
SITE_URL=http://localhost:8000
SUPABASE_PUBLIC_URL=http://localhost:8000
KONG_HTTP_PORT=8000
KONG_HTTPS_PORT=8443
EOF

#!/bin/bash

# Generar archivo docker-compose.yml
cat <<'EOD' > docker-compose.yml
version: '3.8'
services:
  db:
    container_name: supabase-db
    image: supabase/postgres:14
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
  studio:
    container_name: supabase-studio
    image: supabase/studio:20241202-71e5240
    restart: unless-stopped
    environment:
      SUPABASE_URL: http://localhost:8000
      SUPABASE_ANON_KEY: ${ANON_KEY}
      SUPABASE_SERVICE_KEY: ${SERVICE_ROLE_KEY}
EOD

# Desplegar contenedores
docker-compose up -d

# Preguntar al usuario si desea instalar Cloudflare Tunnel
read -p "¿Desea instalar y configurar Cloudflare Tunnel? (s/n): " INSTALL_CLOUDFLARE
if [[ "$INSTALL_CLOUDFLARE" =~ ^[sS]$ ]]; then
    if ! command -v cloudflared &> /dev/null; then
        echo "Instalando Cloudflare Tunnel..."
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    fi

    read -p "Ingrese su token de Cloudflare Tunnel: " CLOUDFLARE_TOKEN

    # Configurar Cloudflare Tunnel como servicio
    cat <<EOF > /etc/systemd/system/cloudflared.service
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
ExecStart=/usr/local/bin/cloudflared tunnel --no-autoupdate run --token $CLOUDFLARE_TOKEN
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable cloudflared
    systemctl start cloudflared
fi

# Guardar información final
cat <<EOF > /opt/supabase/informacion_final.md
### Información de la instalación de Supabase

- **Postgres Password**: $POSTGRES_PASSWORD
- **JWT Secret**: $JWT_SECRET
- **Anon Key**: $ANON_KEY
- **Service Role Key**: $SERVICE_ROLE_KEY
- **URL Local**: http://localhost:8000

EOF

echo "Instalación completada. Verifique el archivo /opt/supabase/informacion_final.md para los detalles de acceso."

