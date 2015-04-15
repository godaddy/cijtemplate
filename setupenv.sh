#!/bin/bash -e


if [ -z $(which python3-pip) ]; then 
    PIP_CMD=$(which pip) 
    PYTHON_CMD=$(which python)
else
    PIP_CMD=$(which python3-pip) 
    PYTHON_CMD=$(which python3)
fi

sudo ${PIP_CMD} install -r pipreqs
if [ -z "$APP_MODE" -o "$APP_MODE" == "dev" ]; then
    sudo ${PIP_CMD} install -r pipreqs-dev
fi
exit 0
