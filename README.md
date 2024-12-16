# Supabase Installation Script

## Descripción
Este repositorio contiene un script automatizado para instalar y configurar Supabase en un servidor Debian. Además, el script ofrece la opción de instalar y configurar un túnel de Cloudflare para exponer la aplicación de forma segura.

## Requisitos previos

Antes de ejecutar el script, asegúrese de cumplir con los siguientes requisitos:

- **Sistema operativo**: Debian 12 o superior.
- **Permisos**: El script debe ejecutarse como usuario `root`.
- **Red**: Acceso a Internet para descargar dependencias y configuraciones.

## Funcionalidades principales

1. **Instalación de Docker y Docker Compose**.
2. **Clonación del repositorio oficial de Supabase**.
3. **Configuración automática de variables de entorno**.
4. **Despliegue de contenedores de Supabase mediante `docker-compose`**.
5. **Opción de instalar y configurar un túnel de Cloudflare**.
6. **Generación de un archivo final con la información de acceso**.

## Instrucciones de instalación

### Paso 1: Descargar el script

Clona este repositorio en tu servidor:

```bash
git clone https://github.com/tu-usuario/tu-repositorio-supabase.git
cd tu-repositorio-supabase
```

### Paso 2: Verificar permisos

Asegúrate de que el script tiene permisos de ejecución:

```bash
chmod +x install_supabase.sh
```

### Paso 3: Ejecutar el script

Ejecuta el script para instalar Supabase y configurar el entorno:

```bash
./install_supabase.sh
```

### Paso 4: Responder las preguntas del script

Durante la ejecución del script:
1. Se generará un archivo `.env` para configurar las variables de entorno necesarias.
2. Se te preguntará si deseas configurar un túnel de Cloudflare:
   - Si eliges **sí**, deberás proporcionar tu token de Cloudflare Tunnel.
   - Si eliges **no**, el script continuará con la instalación básica.

### Paso 5: Verificar la instalación

Una vez completada la instalación, la información de acceso se almacenará en:

```bash
/opt/supabase/informacion_final.md
```

Este archivo incluirá:
- Contraseña de la base de datos PostgreSQL.
- Clave JWT.
- URL de acceso local.

Puedes acceder a Supabase Studio en tu navegador utilizando la URL `http://localhost:3000` (o el dominio configurado en Cloudflare si habilitaste el túnel).

### Paso 6: Verificar el estado de los contenedores

Para verificar que todos los servicios están funcionando correctamente, utiliza:

```bash
docker-compose ps
```

## Solución de problemas

- **Docker no se instala**: Verifica que el sistema tenga acceso a los repositorios oficiales de Docker.
- **Error al iniciar los contenedores**: Asegúrate de que las imágenes de Docker estén actualizadas y no haya conflictos de puertos.
- **Problemas con Cloudflare**: Verifica tu token y las configuraciones en tu cuenta de Cloudflare.
- **Servicios no disponibles**: Revisa los logs con `docker-compose logs` para identificar errores.

## Licencia
Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.


