# Supabase Installation Script

## Descripción
Este repositorio contiene un script automatizado para instalar y configurar Supabase en un servidor Debian. El script también ofrece la opción de instalar y configurar un túnel de Cloudflare para exponer la aplicación de forma segura.

## Requisitos previos

Antes de ejecutar el script, asegúrese de cumplir con los siguientes requisitos:

- **Sistema operativo**: Debian 12 o superior
- **Permisos**: El script debe ejecutarse como usuario `root`
- **Red**: Acceso a Internet para descargar dependencias y configuraciones

## Funcionalidades principales

1. **Instalación de Docker y Docker Compose**
2. **Clonación del repositorio oficial de Supabase**
3. **Configuración automática de variables de entorno**
4. **Despliegue de contenedores de Supabase mediante `docker-compose`**
5. **Opción de instalar y configurar un túnel de Cloudflare**
6. **Generación de un archivo final con la información de acceso**

## Instrucciones de instalación

### Paso 1: Clonar el repositorio

Clona este repositorio en tu servidor:
```bash
git clone https://github.com/tu-usuario/tu-repositorio-supabase.git
cd tu-repositorio-supabase
```

### Paso 2: Ejecutar el script

Asegúrate de que el script tiene permisos de ejecución:
```bash
chmod +x install_supabase.sh
```

Ejecuta el script:
```bash
./install_supabase.sh
```

### Paso 3: Configuración de Cloudflare (opcional)

Durante la ejecución del script, se te preguntará si deseas instalar y configurar un túnel de Cloudflare:
- Si eliges **sí**, deberás proporcionar el token de autenticación de tu túnel de Cloudflare.
- Si eliges **no**, el script continuará con la instalación básica de Supabase.

### Paso 4: Acceso a Supabase

Una vez completada la instalación, la información de acceso se almacenará en:
```bash
/opt/supabase/informacion_final.md
```
Este archivo incluirá:
- Contraseña de la base de datos Postgres
- Claves JWT
- URL de acceso local

Puedes acceder a Supabase en tu navegador utilizando la URL `http://localhost:8000` (o el dominio configurado en Cloudflare si habilitaste el túnel).

## Solución de problemas

- **Docker no se instala**: Verifica que el sistema tenga acceso a los repositorios oficiales de Docker.
- **Error al iniciar los contenedores**: Asegúrate de que no haya conflictos de puertos en el servidor.
- **Problemas con Cloudflare**: Verifica tu token y las configuraciones en tu cuenta de Cloudflare.

## Créditos
Este script fue desarrollado para facilitar la instalación de Supabase y su integración con Cloudflare en entornos Debian.

## Licencia
Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.

