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
    class { 'nginx': }
    nginx::resource::upstream { 'sonar':
        members => [
            '127.0.0.1:9000',
        ],
    }
    nginx::resource::vhost { 'default':
       www_root => '/var/www/html', 
    }
    nginx::resource::location { 'default':
        location => '/sonar',
        proxy => 'http://sonar',
        vhost => 'default'
    }
}

