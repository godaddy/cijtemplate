#!/bin/bash -e
sudo python3-pip install -r pipreqs
if [ -z "$APP_MODE" -o "$APP_MODE" == "dev" ]; then
    sudo python3-pip install -r pipreqs-dev
fi
python3 manage.py migrate
exit 0
