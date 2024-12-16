#!/bin/bash

# Verifica si el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Actualizar e instalar dependencias necesarias
echo "Instalando dependencias necesarias..."
apt update && apt upgrade -y
apt install -y curl wget git ca-certificates gnupg lsb-release software-properties-common unzip

# Instalar Docker si no está instalado
if ! command -v docker &> /dev/null; then
  echo "Docker no está instalado. Procediendo con la instalación..."
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io
  systemctl enable docker
  systemctl start docker
else
  echo "Docker ya está instalado."
fi

# Instalar Docker Compose si no está instalado
if ! command -v docker-compose &> /dev/null; then
  echo "Instalando Docker Compose..."
  curl -L "https://github.com/docker/compose/releases/download/v2.31.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "Docker Compose ya está instalado."
fi

# Eliminar cualquier instalación previa de Supabase
echo "Eliminando cualquier instalación previa de Supabase..."
rm -rf /opt/supabase

# Clonar el repositorio oficial de Supabase
echo "Clonando el repositorio oficial de Supabase..."
git clone --depth 1 https://github.com/supabase/supabase /opt/supabase
cd /opt/supabase/docker || exit 1

# Copiar el archivo de entorno
echo "Copiando archivo .env.example a .env..."
cp .env.example .env

# Editar el archivo .env (opcional, puedes configurar valores predeterminados aquí)
echo "Configurando variables de entorno en .env..."
sed -i 's/^POSTGRES_PASSWORD=.*$/POSTGRES_PASSWORD=$(openssl rand -hex 16)/' .env
sed -i 's/^JWT_SECRET=.*$/JWT_SECRET=$(openssl rand -hex 32)/' .env

# Descargar las últimas imágenes de Docker
echo "Descargando las últimas imágenes de Docker..."
docker-compose pull

# Iniciar los servicios
echo "Iniciando servicios de Supabase..."
docker-compose up -d

# Verificar el estado de los servicios
echo "Verificando el estado de los servicios..."
docker-compose ps

# Preguntar si se desea configurar un túnel de Cloudflare
read -p "¿Deseas configurar un túnel de Cloudflare? (s/n): " configurar_cloudflare
if [[ "$configurar_cloudflare" =~ ^[sS]$ ]]; then
  if ! command -v cloudflared &> /dev/null; then
    echo "Instalando Cloudflare Tunnel..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
  fi

  read -p "Introduce tu token de Cloudflare Tunnel: " token_cloudflare
  cloudflared service uninstall || true
  cloudflared tunnel --no-autoupdate run --token "$token_cloudflare"
  echo "Cloudflare Tunnel configurado correctamente."
else
  echo "Configuración de Cloudflare omitida."
fi

# Mostrar información de acceso final
echo "Supabase se ha instalado correctamente. Información de acceso:"
cat <<EOF > /opt/supabase/informacion_final.md
# Información de acceso a Supabase
- URL de Supabase Studio: http://localhost:3000
- Contraseña de PostgreSQL: $(grep '^POSTGRES_PASSWORD=' .env | cut -d '=' -f2)
- Clave JWT: $(grep '^JWT_SECRET=' .env | cut -d '=' -f2)
EOF

cat /opt/supabase/informacion_final.md

