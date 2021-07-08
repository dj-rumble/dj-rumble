# Dj Rumble

<p align="center">
  <a
    href="https://dj-rumble.herokuapp.com/"
    target="_blank" rel="noopener noreferrer"
  >
    <img
      width="150px" src="assets/static/svg/generic/logo/dj-rumble.svg"
      alt="DjRumble logo"
    />
  </a>
</p>

<h4 align="center">
  Descubre y comparte música en tiempo real con personas de todo el mundo
</h4>

---

<p align="center" style="margin-top: 14px;">
  <a href="https://github.com/dj-rumble/dj-rumble/actions/workflows/dialyzer.yml">
    <img
      src="https://github.com/dj-rumble/dj-rumble/actions/workflows/dialyzer.yml/badge.svg"
      alt="Build Status"
    >
  </a>
  <a href="https://github.com/dj-rumble/dj-rumble/actions/workflows/test.yml">
    <img
      src="https://github.com/dj-rumble/dj-rumble/actions/workflows/test.yml/badge.svg"
      alt="Build Status"
    >
  </a>
  <a href="https://github.com/dj-rumble/dj-rumble/actions/workflows/lint.yml">
    <img
      src="https://github.com/dj-rumble/dj-rumble/actions/workflows/lint.yml/badge.svg"
      alt="Build Status"
    >
  </a>
  <a href="https://www.codacy.com/gh/dj-rumble/dj-rumble/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=dj-rumble/dj-rumble&amp;utm_campaign=Badge_Grade"
  >
    <img
      src="https://app.codacy.com/project/badge/Grade/40d431406d4d4daca2b06a0f965348fe"
      alt="Code Quality Status"
      />
    </a>
  <a href='https://coveralls.io/github/dj-rumble/dj-rumble'>
    <img
      src='https://coveralls.io/repos/github/dj-rumble/dj-rumble/badge.svg'
      alt='Coverage Status'
    />
  </a>
  <a
    href="https://github.com/dj-rumble/dj-rumble/blob/main/LICENSE"
  >
    <img
      src="https://img.shields.io/badge/License-GPL%20v3-blue.svg"
      alt="License"
    >
  </a>
</p>

## Documentación

+ [Wiki](https://github.com/dj-rumble/dj-rumble-app/wiki)
+ [Sprint Actual](https://github.com/dj-rumble/dj-rumble/wiki/POC)

## Entorno de desarrollo

### Requerimientos

+ [Docker](https://docs.docker.com/engine/install/ubuntu/)
+ [Docker Compose](https://docs.docker.com/compose/install/)
+ [Elixir `1.11.4`](https://elixir-lang.org/install.html)
+ [Erlang `23.3.4`](https://erlang.org/doc/installation_guide/users_guide.html)

Elixir y Erlang también pueden ser instalados a través del [manager `asdf`](https://asdf-vm.com/#/core-manage-asdf?id=install). [Guía de instalación alternativa](https://gist.github.com/sgobotta/514a3e452f7bc37c558fc93a2768ccd2) para `asdf`.

 ```bash
 asdf plugin-update --all
 asdf plugin-add erlang
 asdf plugin-add elixir
 asdf install
 ```

Se isntalarán las versiones de Elixir y Erlang declaradas en el archivo `.tool-versions`

### Editores y extensiones recomendadas

+ [*VSCodium*](https://vscodium.com/#install) es la versión libre de Visual Studio Code.
+ [*VSCode*](https://code.visualstudio.com/Download)
+ [*ElixirLS*](https://marketplace.visualstudio.com/items?itemName=JakeBecker.elixir-ls) brinda soporte de debugging, análisis estático, formateo, highlight de código, entre otras características.
+ [*Elixir Linter (Credo)*](https://marketplace.visualstudio.com/items?itemName=pantajoe.vscode-elixir-credo) recomienda formateo de código, oportunidades de refactoring y promueve consistencia de estilo.
+ [*ESLint*](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) promueve consistencia de estilo y buenas prácticas en los módulos Javascript.
+ [*markdownlint*](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint) promueve consistencia de estilo en archivos markdown.

### Git hooks

El proyecto utiliza [`elixir_git_hooks`](https://github.com/qgadrian/elixir_git_hooks) para evitar conflictos durante la integración contínua y simplificar las revisiones de Pull Requests.

La implementación de cada git hook se encuentra en el archivo de configuración [`dev.exs`](config/dev.exs).

Los hooks se instalan automáticamente durante la puesta a punto del proyecto, cuando se instalan las dependencias de elixir: `mix deps.get`, `make install.deps`, `make setup` o `make reset`. Ante algún conflicto, es posible instalar o correr los hooks manualmente desde la terminal:

+ Instalación: `mix git_hooks.install`
+ Correr un hook específico: `mix git_hooks.run pre_commit`
+ Correr todos los hooks: `mix git_hooks.run all`

### Variables de ambiente

Configure un archivo [`.env`](.env) en la raíz del proyecto, utilizando como base el archivo [`.env.example`](.env.example). Luego, asigne los valores correspondientes a cada variable.

```bash
cp .env.example .env
```

#### App

+ `APP_HOST`: su IP de host. **Ejemplo:** `127.0.0.1` (local), `192.168.0.xxx` (lan), `0.0.0.0` (lan)

#### Database

+ `DB_USERNAME`: nombre de usuarix con permisos root para la base de datos del contenedor de `postgres`.
+ `DB_PASSWORD`: contraseña de usuarix con permisos root para la base de datos del contenedor de `postgres`.
+ `DB_USERNAME_TEST`: simil a `DB_USERNAME` pero se utiliza para correr pruebas.
+ `DB_PASSWORD_TEST`: simil a `DB_PASSWORD` pero se utiliza para correr pruebas.

#### Mailing Service

+ `SENDGRID_API_KEY`: Api key del servicio de mailing de Sendgrid.

#### PgAdmin

+ `PGADMIN_DEFAULT_EMAIL`: email para acceder a la instancia de Postgres admin en el contenedor de `pgadmin`.
+ `PGADMIN_DEFAULT_PASSWORD`: contraseña para acceder a la instancia de Postgres admin en el contenedor de `pgadmin`.

#### YouTube

+ `YOUTUBE_API_KEY:` Api key del servicio de búsqueda de YouTube. Más información acerca de [*cómo conseguir una API key*](https://console.developers.google.com/apis/api/youtube.googleapis.com/credentials).

#### Timezone

+ `TZ`: Zona horaria que utiliza el servidor para timestamp de mensajes. [Listado](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) de timezones disponibles y [más información](https://www.iana.org/time-zones) sobre la base de datos de zonas horarias.

### Comandos útiles

Este proyecto utiliza **Makefile** para interactuar con el servidor, los servicios de postgres, la base de datos e instalación del entorno.

> *Obtener más información acerca de los comandos disponibles.*

```bash
make help
```

### Comandos de configuración

> *Instala el ambiente de desarrollo completo. Útil cada vez que se realiza un cambio de rama o se testea un pull request.*

```bash
make setup
```

> *Simula una reinstalación completa del ambiente. Útil ante conflictos de dependencias de cliente o servidor, conflictos de migraciones o durante revisiones de pull requests. Ver `make clean.deps` y `make clean.npm`. En algunos casos, el comando falla y es necesaario actualizar manualmente las dependencias `mix deps.get` antes de proceder con la re-instalación completa del ambiente.*

```bash
make reset
```

> *Elimina la base de datos, reinicia los servicios y vuelve a montar el ambiente de desarrollo. Útil ante revisión de branch que incluyen migraciones y seeds.*

```bash
make ecto.reset
```

### Comandos de servidor

> *Inicia el servidor de desarrollo con una terminal interactiva de Elixir.*

```bash
make server
```

### Comandos de testing

> *Ejecuta todas las pruebas.*

```bash
make test
```

> *Ejecuta únicamente las pruebas con el tag `wip` asignado ([Acerca de tags y tests](https://hexdocs.pm/phoenix/testing.html#running-tests-using-tags)).*

```bash
make test.wip
```

> *Elimina la base de datos de desarrollo. Este comando resulta útil ante conflictos en los esquemas de la base de datos de pruebas.*

```bash
make test.drop
```

> *Corre las pruebas y genera un reporte de coverage.*

```bash
make test.cover
```

> *Corre y observa todas las pruebas o aquellas con el tag `wip`*

```bash
make test.watch
make test.wip.watch
```

### Comandos de análisis

#### Análisis de linting y estilo

Los comandos de linting se utilizan en el workflow [`lint.yml`](.github/workflows.lint.yml). Es recomendable utilizar `make lint.ci` antes de aplicar cambios en la rama para evitar conflictos durante la integración contínua. De todos modos, los hooks de github notificarán errores de linting o de formato al realizar commits.

> *Formatea código, analiza consistencia de estilo y realiza un análisis estático de código.*

```bash
make lint
```

> *Similar a* `make lint` *pero corta la ejecución ante fallas. Útil para simular localmente el proceso de linting de la integración contínua.*

```bash
make lint.ci
```

#### Analisis de seguridad

> *Realiza un análisis de seguridad*.

```bash
make security.check
```

> *Realiza un análisis de seguridad estricto*.

```bash
make security.ci
```

#### Otros

> *Ejecuta localmente todos los chequeos que se realizan durante la CI.*

```bash
make check
```

### Servidor de desarrollo

Una vez configuradas las variables de entorno e instalado el ambiente de desarrollo es posible iniciar el servidor utilizando el comando `make server`.

+ Visite [`localhost:4000`](http://localhost:4000) desde su navegador para acceder a la ruta principal de la aplicación.
+ Visite [`localhost:4000/dashboard`](http://localhost:4000/dashboard/home) desde su navegador para acceder al panel  la ruta principal de la aplicación.

### Administración de bases de datos

Los servicios de Docker incluyen un contenedor de [`PostgreSql`](https://www.postgresql.org/) y una instancia de [`pgAdmin`](https://www.pgadmin.org/).

+ Visite [`localhost:5050`](http://localhost:5050/) desde su navegador e ingrese las credenciales de usuarix configuradas en [`.env`](.env) para acceder al panel de administración.
+ Ingrese al menú `Object` => `Create` => `Server` y otorgue un nombre de fantasía al servidor.
+ Luego, en la pestaña `Connection` utilice el host `main_db` (tal como se declara en `docker-compose.yml`) y las credenciales de base de datos configuradas en [`.env`](.env) para acceder a la base de datos.

## Licencia

[AGPL-3.0](https://github.com/dj-rumble/dj-rumble-app/blob/main/LICENSE)
