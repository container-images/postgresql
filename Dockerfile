# Container artifact for the PostgreSQL module

# This should probably rather be something like...:
# FROM registry.fedoraproject.org/module-base-runtime:26
# ...and probably would:
# - contain microdnf rather than dnf
# - not have any repositories configured
# - need a shared-userspace module repo enabled
FROM registry.fedoraproject.org/fedora:26

# PostgreSQL container image
# Exposed ports:
#  * 5432/tcp - postgres
# Volumes:
#  * /var/lib/psql/data - Database cluster for PostgreSQL


ENV NAME=postgresql \
    VERSION=0 \
    RELEASE=1 \
    ARCH=x86_64 \
    POSTGRESQL_VERSION=9.6 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
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

# Update packages so everything available is current
RUN dnf update -y --setopt=tsflags=nodocs

# Need to have charset files
RUN dnf install -y glibc-locale-source

# orchestration scripts:
# find
RUN dnf install -y findutils
# /usr/bin/envsubst
RUN dnf install -y gettext
# nss_wrapper.so
RUN dnf install -y nss_wrapper
# python
RUN dnf install -y /usr/bin/python

# Install the postgresql server component.
#
# This image must forever use UID 26 for postgres user so our volumes are
# safe in the future. This should *never* change, the last test is there
# to make sure of that.
RUN INSTALL_PKGS="postgresql postgresql-server" && \
    dnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    dnf --enablerepo=\* -y clean all && \
    localedef -f UTF-8 -i en_US en_US.UTF-8 && \
    test "$(id -u postgres)" = "26" && \
    test "$(id -g postgres)" = "26" && \
    mkdir -p /var/lib/pgsql/data && \
    /usr/libexec/fix-permissions /var/lib/pgsql && \
    /usr/libexec/fix-permissions /var/run/postgresql

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/postgresql

VOLUME ["/var/lib/pgsql/data"]

USER 26

ENTRYPOINT ["container-entrypoint"]
CMD ["run-postgresql"]
