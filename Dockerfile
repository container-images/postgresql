# Container artifact for the PostgreSQL module

# This should probably rather be something like...:
# FROM registry.fedoraproject.org/module-base-runtime:26
# ...and probably would:
# - not have any repositories configured
# - need a shared-userspace module repo enabled
FROM baseruntime/baseruntime:latest

# Notes: Current base-runtime images will enable a package repo with all
# packages from the currently latest compose of Fedora 26/Boltron. Buyer
# beware.

# PostgreSQL container image
# Exposed ports:
#  * 5432/tcp - postgres
# Volumes:
#  * /var/lib/psql/data - Database cluster for PostgreSQL


ENV NAME=postgresql \
    VERSION=0 \
    RELEASE=1 \
    ARCH=x86_64 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    POSTGRESQL_VERSION=9.6 \
    HOME=/var/lib/pgsql \
    PGUSER=postgres

LABEL summary = "PostgreSQL is an object-relational DBMS." \
      name = "$FGC/$NAME" \
      version = "$VERSION" \
      release="$RELEASE.$DISTTAG"  \
      architecture = "$ARCH" \
      maintainer = "Nils Philippsen <nils@redhat.com>" \
      description = "PostgreSQL is an advanced Object-Relational database management system (DBMS). This container contains the programs needed to create and run a PostgreSQL server, which will in turn allow you to create and maintain PostgreSQL databases." \
      vendor="Fedora Project" \
      com.redhat.component="$NAME" \
      org.fedoraproject.component="postgresql" \
      authoritative-source-url="registry.fedoraproject.org" \
      usage="docker run -v <dbroot_path>:/var/lib/pgsql:Z -p 5432:5432 -e POSTGRESQL_USER=<user> -e POSTGRESQL_PASSWORD=<password> -e POSTGRESQL_DATABASE=<database> modularitycontainers/postgresql" \
      io.k8s.description = "PostgreSQL is an advanced Object-Relational database management system (DBMS). This container contains the programs needed to create and run a PostgreSQL server, which will in turn allow you to create and maintain PostgreSQL databases." \
      io.k8s.display-name="PostgreSQL ${POSTGRESQL_VERSION}" \
      io.openshift.tags="database,postgresql,postgresql96" \
      io.openshift.expose-services="5432/tcp:postgres"

EXPOSE 5432

ADD root /

COPY root/help.1 /help.1

# Install the postgresql server component.
#
# This image must forever use UID 26 for postgres user so our volumes are
# safe in the future. This should *never* change, the last test is there
# to make sure of that.

# Notes about the below:
# - gettext: /usr/bin/envsubst
# - no working python module yet

RUN \
    microdnf install -y findutils && \
    microdnf install -y gettext && \
    # microdnf install -y nss_wrapper && \
    # microdnf install -y /usr/bin/python && \
    INSTALL_PKGS="postgresql postgresql-server" && \
    microdnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    microdnf -y clean all && \
    # localedef -f UTF-8 -i en_US en_US.UTF-8 && \
    test "$(id postgres)" = "uid=26(postgres) gid=26(postgres) groups=26(postgres)" && \
    mkdir -p /var/lib/pgsql/data && \
    /usr/libexec/fix-permissions /var/lib/pgsql && \
    /usr/libexec/fix-permissions /var/run/postgresql

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/postgresql

VOLUME ["/var/lib/pgsql"]

USER 26

ENTRYPOINT ["container-entrypoint"]
CMD ["run-postgresql"]
