#!/bin/bash
set -e -u -x

function repair_wheel {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel repair "$wheel" --plat "$PLAT" -w /io/wheelhouse/
    fi
}

export SCHEMA_SALAD_USE_MYPYC=1
export MYPYPATH=/io/typeshed/2and3/:/io/typeshed/3

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    if [[ "${PYBIN}" != *"cp27"* ]] ; then
      "${PYBIN}/pip" install -r /io/dev_requirements.txt
      "${PYBIN}/pip" wheel /io/ --no-deps -w wheelhouse/
    fi
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    repair_wheel "$whl"
done

# Install packages and test
for PYBIN in /opt/python/*/bin; do
    if [[ "${PYBIN}" != *"cp27"* ]] ; then
      "${PYBIN}/pip" install schema_salad --no-index -f /io/wheelhouse
      (cd "$HOME"; "${PYBIN}/pytest" --pyargs schema_salad)
    fi
done
