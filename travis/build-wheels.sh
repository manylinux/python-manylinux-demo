#!/bin/bash
set -e -x

function repair_wheel() {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    elif [[ "$wheel" =~ none-any ]]; then
        echo "Skipping pure wheel $wheel"
    elif [[ "$wheel" =~ manylinux ]]; then
        echo "Skipping manylinux wheel $wheel"
    else
        auditwheel repair "$wheel" --plat "$PLAT" -w /io/wheelhouse/ || true
    fi
}

# Install packages required for wheel building
yum install -y zlib-devel bzip2-devel ncurses-devel sqlite-devel \
    readline-devel tk-devel gdbm-devel db4-devel libpcap-develxz-devel gpg \
    atlas-devel libev-devel libev snappy-devel freetype-devel libpng-devel \
    libffi-devel python-lxml postgresql95-libs postgresql95-devel \
    lapack-devel python python-devel python-setuptools pcre pcre-devel pandoc

# psycopg2 won't build without this
releasever=$(cat /etc/redhat-release | cut -d'.' -f1 | cut -d' ' -f3)
yum install -y libxslt-devel
curl https://parsely-public.s3.amazonaws.com/packages/rpm/pgdg95-centos${releasever}.tar.gz -o /tmp/pgdg95-centos${releasever}.tar.gz
tar -zxf /tmp/pgdg95-centos${releasever}.tar.gz -C /tmp
rpm -ivh /tmp/pgdg95-centos${releasever}/*
export PG_HOME=/usr/pgsql-9.5
export PATH=/usr/pgsql-9.5/bin:$PATH

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    if [[ "$PYBIN" =~ cp26 ]]; then
        echo "Skipping 2.6 because it's horrible"
    elif [[ "$PYBIN" =~ cp27 ]]; then
        echo "Skipping 2.7 because we don't use it"
    elif [[ "$PYBIN" =~ cp33 ]]; then
        echo "Skipping 3.3 because we don't use it"
    elif [[ "$PYBIN" =~ cp34 ]]; then
        echo "Skipping 3.4 because we don't use it"
    elif [[ "$PYBIN" =~ cp35 ]]; then
        echo "Skipping 3.5 because we don't use it"
    else
        "${PYBIN}/pip" install --upgrade pip
        CFLAGS="-I/usr/local/ssl/include" LDFLAGS="-L/usr/local/ssl/lib" ${PYBIN}/pip wheel --prefer-binary cryptography -w /io/wheelhouse/ -f /io/wheelhouse
        "${PYBIN}/pip" wheel --prefer-binary -r /io/dev-requirements.txt -w /io/wheelhouse/ -f /io/wheelhouse || true
        # Do another run allowing dev builds, and do it with a separate run per
        # requirement so that one broken prerelease doesn't stop the rest from
        # being build---I'm looking at *you* statsmodel 0.8.0rc1
        cat /io/dev-requirements.txt | tr '\n' '\0' | xargs -0 -I{} bash -c "${PYBIN}/pip wheel --prefer-binary --pre {} -w /io/wheelhouse/ -f /io/wheelhouse || true"
    fi
done

# Bundle external shared libraries into the wheels
for whl in /io/wheelhouse/*.whl; do
    repair_wheel "$whl"
done

# Remove platform-specific wheels
rm -f /io/wheelhouse/*-linux*.whl
