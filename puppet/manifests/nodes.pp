# Puppet Manifest

class { 'hosttype_default': }

case $::hostname {
    /jenkins/: {
        class { 'hosttype_jenkins': }
    }
    /test/: {
    }
    /prod/: {

    }
    default: {
    }
}
