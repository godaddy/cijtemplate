class hosttype_jenkins {
    class { 'java': }
    class { 'maven::maven' : }
    class { 'sonarqube' :
      version       => '5.1',
      installroot   => '/opt/sonar',
      home          => '/opt/sonar',
      web_java_opts => '-Xmx512m',
      log_folder    => '/opt/sonar/logs',
    }
}
