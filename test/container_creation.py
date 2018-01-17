import os
import logging

from conu import DockerBackend, DockerRunBuilder
from conu import Probe, ProbeTimeout, random_str

import pytest

BACKEND = DockerBackend(logging_level=logging.DEBUG)
pg_image = None


def get_image():
    global pg_image
    if pg_image is None:
        image_name = os.environ['IMAGE_NAME']
        pg_image = BACKEND.ImageClass(image_name, tag='latest')
    return pg_image


@pytest.mark.parametrize(
    "invalid_values", [
        {
            "description": "number in user name",
            "options":
                ["-e", "POSTGRESQL_USER=0invalid",
                 "-e", "POSTGRESQL_PASSWORD=pass",
                 "-e", "POSTGRESQL_DATABASE=db",
                 "-e", "POSTGRESQL_ADMIN_PASSWORD=admin_pass"]
        },
        {
            "description": "database name too long",
            "options":
                ["-e", "POSTGRESQL_USER=user",
                 "-e", "POSTGRESQL_PASSWORD=pass",
                 "-e", "POSTGRESQL_DATABASE=" + random_str(size=64),
                 # "-e", "POSTGRESQL_DATABASE=db",
                 "-e", "POSTGRESQL_ADMIN_PASSWORD=admin_pass"]
        },
        {
            "description": "backslash in admin password",
            "options":
                ["-e", "POSTGRESQL_USER=user",
                 "-e", "POSTGRESQL_PASSWORD=pass",
                 "-e", "POSTGRESQL_DATABASE=db",
                 "-e", "POSTGRESQL_ADMIN_PASSWORD=\""]
        },
        {
            "description": "user name too long",
            "options":
                ["-e", "POSTGRESQL_USER=" + random_str(size=64),
                 "-e", "POSTGRESQL_PASSWORD=pass",
                 "-e", "POSTGRESQL_DATABASE=db",
                 "-e", "POSTGRESQL_ADMIN_PASSWORD=admin_pass"]
        },
        {
            "description": "backslash in password",
            "options":
                ["-e", "POSTGRESQL_USER=user",
                 "-e", "POSTGRESQL_PASSWORD=\"",
                 "-e", "POSTGRESQL_DATABASE=db",
                 "-e", "POSTGRESQL_ADMIN_PASSWORD=admin_pass"]
        },
        {
            "description": "number in database name",
            "options":
                ["-e", "POSTGRESQL_USER=user",
                 "-e", "POSTGRESQL_PASSWORD=pass",
                 "-e", "POSTGRESQL_DATABASE=9invalid",
                 "-e", "POSTGRESQL_ADMIN_PASSWORD=admin_pass"]
        },
        {
            "description": "missing user name",
            "options":
                ["-e", "POSTGRESQL_PASSWORD=pass",
                 "-e", "POSTGRESQL_DATABASE=db"]
        },
        {
            "description": "missing password",
            "options":
                ["-e", "POSTGRESQL_USER=user",
                 "-e", "POSTGRESQL_DATABASE=db"]
        },
        {
            "description": "missing database name",
            "options":
                ["-e", "POSTGRESQL_USER=user",
                 "-e", "POSTGRESQL_PASSWORD=pass"]
        },
        {
            "description": "admin password, user and password set, but user name missing",
            "options":
                ["-e", "POSTGRESQL_PASSWORD=pass",
                 "-e", "POSTGRESQL_DATABASE=db",
                 "-e", "POSTGRESQL_ADMIN_PASSWORD=admin_pass"]
        },
        {
            "description": "admin password, user name and password set, but database name missing",
            "options":
                ["-e", "POSTGRESQL_USER=user",
                 "-e", "POSTGRESQL_PASSWORD=pass",
                 "-e", "POSTGRESQL_ADMIN_PASSWORD=admin_pass"]
        }
    ]
)
def test_invalid_env_values(invalid_values):
    assert_container_creation_fails(invalid_values["options"], invalid_values["description"])


# TODO: move to conu
def assert_container_creation_fails(opts, description):
    cmd = DockerRunBuilder(additional_opts=opts)
    image = get_image()
    cont = image.run_via_binary(cmd)

    p = Probe(timeout=9, fnc=cont.get_status, expected_retval='exited')
    try:
        p.run()
    except ProbeTimeout:
        actual_status = cont.get_status()
        cont.stop()
        cont.delete()
        if actual_status == 'running':
            raise RuntimeError("Container should fail with %s" % description)
        else:
            raise RuntimeError("Container reached unexpected status %s" % actual_status)

    ec = cont.get_metadata()['State']['ExitCode']
    print(cont.logs())
    assert ec != 0, "Container should exit wit non-zero exit code when input is invalid"
    cont.delete()
