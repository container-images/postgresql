import os
import logging

from conu import DockerBackend, DockerRunBuilder

import pytest


testcontainers = [
    {
        "description": "no_admin",
        "options":
            {
             "POSTGRESQL_USER" : "user",
             "POSTGRESQL_PASSWORD" : "pass",
             "POSTGRESQL_DATABASE" : "db",
             "POSTGRESQL_MAX_CONNECTIONS" : "42",
             "POSTGRESQL_MAX_PREPARED_TRANSACTIONS" : "42",
             "POSTGRESQL_SHARED_BUFFERS" : "64MB"
            }
    },
    {
        "description": "admin",
        "options":
            {"POSTGRESQL_USER" : "user1",
             "POSTGRESQL_PASSWORD" : "pass1",
             "POSTGRESQL_DATABASE" : "db",
             "POSTGRESQL_ADMIN_PASSWORD" : "r00t"}
    }
]

BACKEND = DockerBackend(logging_level=logging.DEBUG)
pg_version = '9.6.2'

pg_image = None


def get_image():
    global pg_image
    if pg_image is None:
        image_name = os.environ['IMAGE_NAME']
        pg_image = BACKEND.ImageClass(image_name, tag='latest')
    return pg_image


def make_pg_client_request(container, pg_cmd, opts, expected_output=None):
    cmd = DockerRunBuilder(
        additional_opts = ["-e", "PGPASSWORD=" + opts['POSTGRESQL_PASSWORD']],
        command= ["psql",
                  "postgresql://" + opts['POSTGRESQL_USER'] + "@"
                  + container.get_IPv4s()[0] + ":5432/" + opts['POSTGRESQL_DATABASE'],
                  "-c", pg_cmd]
    )
    client_container = get_image().run_via_binary(cmd)
    assert not expected_output or client_container.logs() == expected_output
    client_container.wait(timeout=10)
    assert client_container.exit_code() == 0
    assert client_container.logs() == expected_output
    client_container.delete()


def build_variable_list(opts):
    var_list = []
    for key, val in opts.items():
        var_list.append("-e")
        var_list.append(key + "=" + val)
    return var_list


@pytest.mark.parametrize(
    "testenv", testcontainers
)
def test_run_container(testenv):
    i = get_image()

    cmd = DockerRunBuilder(additional_opts=build_variable_list(testenv['options']))
    container = i.run_via_binary(cmd)
    container.wait_for_port(5432)
    expected_output = b' ?column? \n----------\n        1\n(1 row)\n'
    make_pg_client_request(container, "SELECT 1;", testenv['options'],
                           expected_output=expected_output)


@pytest.mark.parametrize(
    "testenv", testcontainers
)
def test_version(testenv):
    i = get_image()
    cmd = DockerRunBuilder(
        additional_opts=build_variable_list(testenv['options']),
        command=["psql", "--version"]
    )

    cont = i.run_via_binary(cmd)
    cont.wait()

    out = 'b\'psql (PostgreSQL) ' + pg_version + '\\n\''
    assert str(cont.logs()) == out

