from subprocess import call
from sniffer.api import runnable, file_validator
import os


@file_validator
def py_files(filename):
    is_match = (filename.endswith('.py')
                and not filename.endswith('_flymake.py')
                and not os.path.basename(filename).startswith('.'))
    return is_match


@runnable
def execute_tests(*args):
    fn = ['python3', 'manage.py', 'test']
    fn += args[1:]
    return call(fn) == 0
