manylinux-wheel-builder
=====================
This project builds wheels for all our dependencies to put on our PyPI server. It is a replacement for https://github.com/Parsely/manylinux which was a much more complicated approach to the same thing.

[![Build Status](https://travis-ci.org/Parsely/manylinux-wheel-builder.svg?branch=master)](https://travis-ci.org/Parsely/manylinux-wheel-builder)


This uses Travis-CI to build
[PEP 513](https://www.python.org/dev/peps/pep-0513/)-compatible
wheels for Python. It supports

- manylinux1 for both Python 2 and 3 on 32 and 64 bit linux architectures.
- manylinux2010 for Python 2 and 3 on 64 bit linux architectures.

Continuous integration setup with Travis + Docker
-------------------------------------------------

The `.travis.yml` file in this repository sets up the build environment. The
resulting build logs can be found at

  https://travis-ci.org/Parsely/manylinux-wheel-builder

The `.travis.yml` file instructs Travis to run the script
`travis/build-wheels.sh` inside of the various docker build environments. This
script builds the package using `pip`. But these wheels link against an
external library. So to create self-contained wheels, the build script runs the
wheels through [`auditwheel`](https://pypi.python.org/pypi/auditwheel), which
copies the external library into the wheel itself, so that users won't need to
install any extra non-PyPI dependencies.

Finally, it uses Travis-CI's deploy feature to upload these wheels to S3 and then syncs them to our PyPI server
