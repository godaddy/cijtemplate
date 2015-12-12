class hosttype_jenkins {
    class { 'java': }
    class { 'maven::maven' : }
    class { 'sonarqube' :
      version       => '5.1',
      installroot   => '/opt/sonar',
      home          => '/opt/sonar',
      log_folder    => '/opt/sonar/logs',
      host          => '127.0.0.1',
      context_path  => '/sonar',
    }
    $certdir = "/etc/pki/tls/certs"
    exec {'create_self_signed_sslcert_for_nginx':
      command => "openssl req -newkey rsa:2048 -nodes -keyout server.key  -x509 -days 365 -out server.crt -subj '/CN=${::fqdn}'",
      cwd     => $certdir,
      creates => [ "${certdir}/server.key", "${certdir}/server.crt", ],
      path    => ["/usr/bin", "/usr/sbin"],
      unless => "/usr/bin/test -f ${certdir}/server.key && /usr/bin/test -f ${certdir}/server.crt",
    }
    $jci_config_hash = {
        'JENKINS_LISTEN_ADDRESS' => { value => '127.0.0.1' },
        'JENKINS_AJP_LISTEN_ADDRESS' => { value => '127.0.0.1' },
        'PREFIX' => { value => '/jenkins' },
    }
    class { 'jenkins':
      executors => 0,
      install_java => false,
      config_hash => $jci_config_hash,
    }

    # jenkins::plugin { 'github-api': }
    # jenkins::plugin { 'credentials': }
    # jenkins::plugin { 'plain-credentials': }
    # jenkins::plugin { 'ssh-credentials': }
    # jenkins::plugin { 'git-client': }
    # jenkins::plugin { 'scm-api': }
    # jenkins::plugin { 'mailer': }
    # jenkins::plugin { 'git': }
    # jenkins::plugin { 'github': }
    # jenkins::plugin { 'build-monitor-plugin': }

    class { 'nginx': 
        require => Exec['create_self_signed_sslcert_for_nginx'],
    }
    nginx::resource::upstream { 'sonar':
        members => [
            '127.0.0.1:9000',
        ],
    }
    nginx::resource::upstream { 'jenkins':
        members => [
            '127.0.0.1:8080',
        ],
    }
    nginx::resource::location { 'sonar':
        location => '/sonar',
        proxy => 'http://sonar',
        vhost => 'myserver',
        ssl => true,
        ssl_only => true,
    }
    nginx::resource::location { 'jenkins':
        location => '/jenkins',
        proxy => 'http://jenkins',
        vhost => 'myserver',
        ssl => true,
        ssl_only => true,
    }
    nginx::resource::vhost { 'myserver':
        www_root => '/var/www/html', 
        ssl => true,
        listen_port => 443,
        ssl_port => 443,
        ssl_cert             => "${certdir}/server.crt",
        ssl_key              => "${certdir}/server.key",
    }
    nginx::resource::vhost { "myserver-http":
        ensure              => present,
        www_root            => "/var/www/html",
        location_cfg_append => { 'rewrite' => '^ https://$host$request_uri? permanent' },
    }
}
