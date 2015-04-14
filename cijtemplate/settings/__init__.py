import os

mode = os.environ.get('APP_MODE', 'dev')
print('APP_MODE "%s"' % mode)

# base = common settings
from .base import *

if mode == 'dev':
    from .dev import *
elif mode == 'test':
    from .test import *
elif mode == 'prod':
    from .prod import *
else:
    raise Exception('Unknown APP_MODE "%s"' % mode)
