import os
import importlib


class Settings():
    def __init__(self):
        module = importlib.import_module('conf.base_settings')
        self._set_properties(module)
        self._override_by_environment()

    def _set_properties(self, module):
        for setting in dir(module):
            if setting.isupper():
                value = getattr(module, setting)
                setattr(self, setting, value)

    def _override_by_environment(self):
        self.MODE = self._get_environment()

        try:
            module = importlib.import_module('conf.{}_settings'.format(self.MODE))
            self._set_properties(module)

        except ImportError:
            pass

    def _get_environment(self):
        return os.environ.get('APP_MODE', 'dev')


settings = Settings()
