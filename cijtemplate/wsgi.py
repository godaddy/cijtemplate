"""
WSGI config for cijtemplate project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/1.7/howto/deployment/wsgi/
"""
import os
import sys

current_path = os.getcwd()
project_path = os.path.dirname(current_path)
sys.path.append(project_path)
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "cijtemplate.settings")

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
