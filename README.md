# Dj Rumble

## Documentación

+ [Wiki](https://github.com/dj-rumble/dj-rumble-app/wiki)
+ [Sprint Actual](https://github.com/dj-rumble/dj-rumble/wiki/POC)

## Entorno de desarrollo

### Requerimientos

+ [Docker](https://docs.docker.com/engine/install/ubuntu/)
+ [Docker Compose](https://docs.docker.com/compose/install/)
+ [Elixir](https://elixir-lang.org/install.html)

### Variables de ambiente

Configure un archivo `.env` en la raíz del proyecto, utilizando como base el archivo `.env.example`. Luego, asigne los valores correspondientes a cada variable.

```bash
cp .env .env.example
```

+ `APP_HOST`: su IP de host. **Ejemplo:** `127.0.0.1` (local), `192.168.0.xxx` (lan), `0.0.0.0` (lan)
+ `DB_USERNAME`: nombre de usuarix con permisos root para la base de datos del contenedor de `postgres`.
+ `DB_PASSWORD`: contraseña de usuarix con permisos root para la base de datos del contenedor de `postgres`.
+ `PGADMIN_DEFAULT_EMAIL`: email para acceder a la instancia de Postgres admin en el contenedor de `pgadmin`.
+ `PGADMIN_DEFAULT_PASSWORD`: contraseña para acceder a la instancia de Postgres admin en el contenedor de `pgadmin`.

### Comandos útiles

Este proyecto utiliza **Makefile** para interactuar con el servidor, los servicios de postgres, la base de datos e instalación del entorno.

*Obtener más información acerca de los comandos disponibles.*

```bash
make help
```

*Instala el ambiente de desarrollo completo.*

```bash
make setup
```

*Simula una reinstalación completa del ambiente. Útil ante conflictos de dependencias de cliente o servidor. Ver `make clean.deps` y `make clean.npm`.*

```bash
make reset
```

*Elimina la base de datos, reinicia los servicios y vuelve a montar el ambiente de desarrollo. Útil ante revisión de branch que incluyen migraciones y seeds.*

```bash
make ecto.reset
```

*Inicia el servidor de desarrollo con una terminal interactiva de Elixir.*

```bash
make server
```

*Ejecuta todas las pruebas*

```bash
make test
```

*Corre únicamente las pruebas con el tag `wip` asignado ([Documentación sobre utilización de tags](https://hexdocs.pm/phoenix/testing.html#running-tests-using-tags)).*


```bash
make test.wip
```

*Elimina la base de datos de desarrollo. Este comando resulta útil ante conflictos en los esquemas de la base de datos de pruebas.*

```bash
make test.drop
```

### Servidor de desarrollo

Una vez configuradas las variables de entorno e instalado el ambiente de desarrollo es posible iniciar el servidor utilizando el comando `make server`.

+ Visite [`localhost:4000`](http://localhost:4000) desde su navegador para acceder a la ruta principal de la aplicación.
+ Visite [`localhost:4000/dashboard`](http://localhost:4000/dashboard/home) desde su navegador para acceder al panel  la ruta principal de la aplicación.

### Administración de bases de datos

Los servicios de docker incluyen un contenedor de [`PostgreSql`](https://www.postgresql.org/) y una instancia de [`pgAdmin`](https://www.pgadmin.org/).

+ Visite [`localhost:5050`](http://localhost:5050/) desde su navegador e ingrese las credenciales configuradas en `.env` para acceder al panel de administración.
+ Ingrese al menú `Object` => `Create` => `Server` y otorgue un nombre de fantasía al servidor.
+ Luego, en la pestaña `Connection` utilice el host `main_db` (tal como se declara en `docker-compose.yml`) y las credenciales proporcionadas en `.env` para acceder a la base de datos.

## Licencia

[AGPL-3.0](https://github.com/dj-rumble/dj-rumble-app/blob/main/LICENSE)
