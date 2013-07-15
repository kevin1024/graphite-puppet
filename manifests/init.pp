class graphite ($http_username, $http_password, $default_retention="60s:30d") {
  include python
  include apache

  package {['python-whisper', 'python-carbon', 'graphite-web', 'python-memcached', 'python-ldap', 'memcached']:
    ensure => 'latest'
  }

  service { 'carbon-cache':
    ensure => 'running',
    enable => true,
    require => Package['python-carbon'],
  }

  file {'/etc/carbon/storage-schemas.conf':
    content => template('graphite/storage-schemas.conf'),
    require => Package['python-carbon'],
    notify  => Service['carbon-cache'],
  }

  file {'/etc/carbon/storage-aggregation.conf':
    content => template('graphite/storage-aggregation.conf'),
    require => Package['python-carbon'],
    notify  => Service['carbon-cache'],
  }

  file {'/etc/graphite-web/local_settings.py':
    content => template('graphite/local_settings.py'),
    require => Package['graphite-web'],
    notify  => Service['httpd'],
  }

  file {'/etc/httpd/conf.d/auth.conf':
    content => template('graphite/auth.conf'),
    require => Package['graphite-web'],
    notify  => Service['httpd'],
  }

  exec {'createpasswords':
    command => "/usr/bin/htpasswd -nbs '${http_username}' '${http_password}' > /etc/graphite-web/users",
    unless  => "/usr/bin/test $(/usr/bin/htpasswd -nbs '${http_username}' '${http_password}') = $(cat /etc/graphite-web/users)",
    require => [Package['graphite-web'], File['/etc/graphite-web/local_settings.py']],
  }

  exec {'syncdb':
    command => '/usr/bin/python /usr/lib/python2.6/site-packages/graphite/manage.py syncdb --noinput',
    unless  => '/usr/bin/python /usr/lib/python2.6/site-packages/graphite/manage.py inspectdb | grep auth_user',
    require => [Package['graphite-web'], File['/etc/graphite-web/local_settings.py']],
    user    => "apache",
  }

}
