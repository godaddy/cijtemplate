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
    class { 'nginx': 
        require => Exec['create_self_signed_sslcert_for_nginx'],
    }
    nginx::resource::upstream { 'sonar':
        members => [
            '127.0.0.1:9000',
        ],
    }
    nginx::resource::location { 'sonar':
        location => '/sonar',
        proxy => 'http://sonar',
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
}
