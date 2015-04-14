import fabric
from fabric.api import run, sudo, cd, env, settings
from fabric.network import disconnect_all
from datetime import datetime, time

service_acct = 'jenkins'

def deploy(commit_hash=None):
    base_dir = '/opt/cijtemplate'
    current_dir = '{}/current'.format(base_dir)
    with settings(warn_only=True):
        if run('test -d {}'.format(current_dir)).succeeded:
            rollback_dir = run('readlink {0}'.format(current_dir))
            print('rollback dir: {}'.format(rollback_dir))
    code_dir = '{}/{}'.format(base_dir, datetime.now().strftime('%Y%m%d%H%M%S'))

    sudo('mkdir -p {}'.format(base_dir))
    sudo('chown {}: {}'.format(service_acct, base_dir))
    run('git clone -q git@github.com:godaddy/cijtemplate.git {}'.format(code_dir))
    if commit_hash is not None:
        run('cd {}; git checkout {}'.format(code_dir, commit_hash))

    with cd(code_dir):
        run('./setupenv.sh')
        run('python3 manage.py migrate')
    sudo('rm -f {}'.format(current_dir))
    sudo('ln -s {} {}'.format(code_dir, current_dir))
    sudo('touch {}/cijtemplate/tmp/restart.txt'.format(current_dir))
    sudo('chown -R jenkins: {}'.format(code_dir))
    sudo('chown -R jenkins: {}'.format(current_dir))
