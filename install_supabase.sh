#!/bin/bash

# Actualizar el sistema
apt update && apt upgrade -y

# Instalar dependencias básicas
apt install -y curl wget git ca-certificates gnupg lsb-release software-properties-common unzip

# Instalar Docker
if ! command -v docker &> /dev/null; then
    echo "Docker no está instalado. Procediendo con la instalación..."
    wget -qO- https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
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
    wget -qO /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/$(wget -qO- https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)/docker-compose-$(uname -s)-$(uname -m)"
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

# Navegar al directorio de Docker
cd docker

# Configurar las variables de entorno necesarias de forma desatendida
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
PGRST_DB_SCHEMAS=public
JWT_EXPIRY=3600
FUNCTIONS_VERIFY_JWT=true
POOLER_TENANT_ID=default
POOLER_DEFAULT_POOL_SIZE=10
POOLER_MAX_CLIENT_CONN=50
POOLER_PROXY_PORT_TRANSACTION=6543
LOGFLARE_API_KEY=
DOCKER_SOCKET_LOCATION=/var/run/docker.sock
STUDIO_DEFAULT_ORGANIZATION=default-org
STUDIO_DEFAULT_PROJECT=default-project
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=securepassword
ENABLE_EMAIL_SIGNUP=true
ENABLE_ANONYMOUS_USERS=true
ENABLE_EMAIL_AUTOCONFIRM=true
SMTP_USER=smtp-user
SMTP_PASS=smtp-pass
SMTP_SENDER_NAME=Supabase
MAILER_URLPATHS_CONFIRMATION=/confirm
ENABLE_PHONE_AUTOCONFIRM=true
MAILER_URLPATHS_RECOVERY=/recover
MAILER_URLPATHS_INVITE=/invite
SMTP_HOST=smtp.example.com
SMTP_PORT=587
API_EXTERNAL_URL=http://localhost:8000
ADDITIONAL_REDIRECT_URLS=http://localhost:8000
SMTP_ADMIN_EMAIL=admin@example.com
MAILER_URLPATHS_EMAIL_CHANGE=/change-email
ENABLE_PHONE_SIGNUP=true
DISABLE_SIGNUP=false
IMGPROXY_ENABLE_WEBP_DETECTION=true
EOF

# Crear archivo docker-compose.yml con la configuración proporcionada
cat <<'EOD' > docker-compose.yml
name: supabase

services:
  studio:
    container_name: supabase-studio
    image: supabase/studio:20241202-71e5240
    restart: unless-stopped
    healthcheck:
      test:
        [
          "CMD",
          "node",
          "-e",
          "fetch('http://studio:3000/api/profile').then((r) => {if (r.status !== 200) throw new Error(r.status)})"
        ]
      timeout: 10s
      interval: 5s
      retries: 3
    depends_on:
      analytics:
        condition: service_healthy
    environment:
      STUDIO_PG_META_URL: http://meta:8080
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      DEFAULT_ORGANIZATION_NAME: \${STUDIO_DEFAULT_ORGANIZATION}
      DEFAULT_PROJECT_NAME: \${STUDIO_DEFAULT_PROJECT}
      OPENAI_API_KEY: \${OPENAI_API_KEY:-}
      SUPABASE_URL: http://kong:8000
      SUPABASE_PUBLIC_URL: \${SUPABASE_PUBLIC_URL}
      SUPABASE_ANON_KEY: \${ANON_KEY}
      SUPABASE_SERVICE_KEY: \${SERVICE_ROLE_KEY}
      AUTH_JWT_SECRET: \${JWT_SECRET}
      LOGFLARE_API_KEY: \${LOGFLARE_API_KEY}
      LOGFLARE_URL: http://analytics:4000
      NEXT_PUBLIC_ENABLE_LOGS: true
      NEXT_ANALYTICS_BACKEND_PROVIDER: postgres

  kong:
    container_name: supabase-kong
    image: kong:2.8.1
    restart: unless-stopped
    entrypoint: bash -c 'eval "echo \"\$\$(cat ~/temp.yml)\"" > ~/kong.yml && /docker-entrypoint.sh kong docker-start'
    ports:
      - "8000:8000"
      - "8443:8443"
    depends_on:
      analytics:
        condition: service_healthy
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /home/kong/kong.yml
      KONG_DNS_ORDER: LAST,A,CNAME
      KONG_PLUGINS: request-transformer,cors,key-auth,acl,basic-auth
      SUPABASE_ANON_KEY: \${ANON_KEY}
      SUPABASE_SERVICE_KEY: \${SERVICE_ROLE_KEY}
      DASHBOARD_USERNAME: \${DASHBOARD_USERNAME}
      DASHBOARD_PASSWORD: \${DASHBOARD_PASSWORD}
    volumes:
      - ./volumes/api/kong.yml:/home/kong/temp.yml:ro
EOD
#!/bin/bash

  auth:
    container_name: supabase-auth
    image: supabase/gotrue:v2.164.0
    depends_on:
      db:
        condition: service_healthy
      analytics:
        condition: service_healthy
    healthcheck:
      test:
        ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9999/health"]
      timeout: 5s
      interval: 5s
      retries: 3
    restart: unless-stopped
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      API_EXTERNAL_URL: \${API_EXTERNAL_URL}
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://supabase_auth_admin:\${POSTGRES_PASSWORD}@\${POSTGRES_HOST}:\${POSTGRES_PORT}/\${POSTGRES_DB}
      GOTRUE_SITE_URL: \${SITE_URL}
EOD

# Configurar y levantar los contenedores
docker-compose up -d

# Preguntar al usuario si desea instalar y configurar Cloudflare Tunnel
read -p "¿Desea instalar y configurar Cloudflare Tunnel? (s/n): " INSTALL_CLOUDFLARE
if [[ "$INSTALL_CLOUDFLARE" =~ ^[sS]$ ]]; then
    # Instalar Cloudflare Tunnel
    if ! command -v cloudflared &> /dev/null; then
        echo "Instalando Cloudflare Tunnel..."
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    else
        echo "Cloudflare Tunnel ya está instalado."
    fi

    # Solicitar la key de Cloudflare Tunnel
    read -p "Ingrese su token de Cloudflare Tunnel: " CLOUDFLARE_TOKEN

    # Configurar el servicio de Cloudflare Tunnel
    echo "Configurando Cloudflare Tunnel como servicio..."
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

    # Recargar y habilitar el servicio de Cloudflare
    systemctl daemon-reload
    systemctl enable cloudflared
    systemctl start cloudflared
fi

# Comprobar el estado de los contenedores
docker-compose ps

# Guardar la información final en un archivo
cat <<EOF > /opt/supabase/informacion_final.md
### Información de la instalación de Supabase

- **Postgres Password**: $POSTGRES_PASSWORD
- **JWT Secret**: $JWT_SECRET
- **Anon Key**: $ANON_KEY
- **Service Role Key**: $SERVICE_ROLE_KEY
- **Acceso local**: [http://localhost:8000](http://localhost:8000)

EOF

# Información final
echo "\nSupabase se ha instalado y está en ejecución."
echo "Accede al puerto 8000 para verificar la instalación."
echo "Postgres Password: $POSTGRES_PASSWORD"
echo "JWT Secret: $JWT_SECRET"
echo "Anon Key: $ANON_KEY"
echo "Service Role Key: $SERVICE_ROLE_KEY"
