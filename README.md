# PostgreSQL

PostgreSQL is an object-relational Database Management System.

This is based on the SCL container image for version 9.5 at:

https://github.com/sclorg/postgresql-container

## Configuration

You must either specify the following environment variables:

* POSTGRESQL_USER
* POSTGRESQL_PASSWORD
* POSTGRESQL_DATABASE

Or the following environment variable:

* POSTGRESQL_ADMIN_PASSWORD

Or both.

Optional settings:

* POSTGRESQL_MAX_CONNECTIONS (default: 100)
* POSTGRESQL_MAX_PREPARED_TRANSACTIONS (default: 0)
* POSTGRESQL_SHARED_BUFFERS (default: 32MB)

## Running in docker

```
docker run -v <dbroot_path>:/var/lib/pgsql:Z -p 5432:5432 -e POSTGRESQL_USER=<user> -e POSTGRESQL_PASSWORD=<password> -e POSTGRESQL_DATABASE=<database> modularitycontainers/postgresql
```

Substitute these placeholders with real values:

* `dbroot_path` - path to the database root on the host which should be mounted
  on `/var/lib/pgsql` in the container. Note that the `postgres` user (uid 26)
  needs to be able to read and write in that directory.
* `user`, `password`, `database` - details with which a database and user
  should be created if the database cluster directory isn't initialized yet.
