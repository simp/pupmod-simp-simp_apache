# == Class: apache::conf
#
# This class sets up apache.conf.
#
# == Parameters
#
# NOTE: If a parameter is not listed here then it is part of the
# standard Apache configuration set and the stock Apache documentation
# should be referenced.
#
# [*httpd_timeout*]
#   Type: Integer
#   The Timeout variable. Renamed to not conflict with the Puppet
#   reserved word 'timeout'.
#
# [*httpd_loglevel*]
#   Type: String
#   The LogLevel variable. Renamed to not conflict with the Puppet
#   reserved word 'loglevel'.
#
# [*listen*]
#   Type: Array of Integers
#   An array of ports upon which Apache should listen.
#
# [*enable_iptables*]
#   Type: Boolean
#   Whether or not to use the SIMP IPTables module.
#
# [*enable_rsyslog*]
#   Type: Boolean
#   Whether or not to use the SIMP Rsyslog module.
#
# [*rsyslog_target*]
#   Type: Absolute Path
#   If $enable_rsyslog is true, store the apache logs at this
#   location.
#
# [*purge*]
#   Type: Boolean
#   Whether or not to purge the configuration directories.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class apache::conf (
  $httpd_timeout = '120',
  $keepalive = 'off',
  $maxkeepalive = '100',
  $keepalivetimeout = '15',
  $prefork_startservers = '8',
  $prefork_minspareservers = '5',
  $prefork_maxspareservers = '20',
  $prefork_serverlimit = '3000',
  $prefork_maxclients = '3000',
  $prefork_maxrequestsperchild = '4000',
  $worker_startservers = '2',
  $worker_maxclients = '3000',
  $worker_minsparethreads = '25',
  $worker_maxsparethreads = '75',
  $worker_threadsperchild = '25',
  $worker_maxrequestsperchild = '0',
  $listen = '80',
  $includes = 'nil',
  $serveradmin = 'root@localhost',
  $servername = 'nil',
  $allowroot = ['127.0.0.1','::1'],
  $defaulttype = 'text/plain',
  $enablemmap = 'on',
  $enablesendfile = 'on',
  $user = 'apache',
  $group = 'apache',
  $httpd_loglevel = 'warn',
  $logformat = '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
  $logfacility = 'local6',
  $enable_iptables = true,
  $rsyslog_target = '/var/log/httpd',
  $purge = true
) {
  include 'apache'

  validate_integer($httpd_timeout)
  validate_array_member($keepalive,['on','off'])
  validate_integer($maxkeepalive)
  validate_integer($keepalivetimeout)
  validate_integer($prefork_startservers)
  validate_integer($prefork_minspareservers)
  validate_integer($prefork_maxspareservers)
  validate_integer($prefork_serverlimit)
  validate_integer($prefork_maxclients)
  validate_integer($prefork_maxrequestsperchild)
  validate_integer($worker_startservers)
  validate_integer($worker_maxclients)
  validate_integer($worker_minsparethreads)
  validate_integer($worker_maxsparethreads)
  validate_integer($worker_threadsperchild)
  validate_integer($worker_maxrequestsperchild)
  validate_array_member($enablemmap,['on','off'])
  validate_array_member($enablesendfile,['on','off'])
  validate_bool($enable_iptables)
  validate_absolute_path($rsyslog_target)
  validate_bool($purge)

  # Make sure the networks are all formatted correctly for Apache.
  $l_allowroot = munge_httpd_networks($allowroot)

  file { [
    '/etc/httpd/conf',
    '/etc/httpd/conf.d'
  ]:
    owner    => 'root',
    group    => $group,
    mode     => '0640',
    recurse  => true,
    purge    => $purge,
    checksum => undef,
  }

  file { '/etc/httpd/conf/httpd.conf':
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => template('apache/etc/httpd/conf/httpd.conf.erb'),
    notify  => Service['httpd']
  }

  if $enable_iptables {
    include 'iptables'

    iptables::add_tcp_stateful_listen { 'allow_http':
      order       => '11',
      client_nets => $l_allowroot,
      dports      => $listen
    }
  }

  if $::use_simp_logging or hiera('use_simp_logging',false) {
    include 'rsyslog'

    rsyslog::rule::local { '10apache_error':
      rule            => 'if ($programname == \'httpd\' and $syslogseverity-text == \'err\') then',
      target_log_file => "${rsyslog_target}/error_log",
      stop_processing => true
    }
    rsyslog::rule::local { '10apache_access':
      rule            => 'if ($programname == \'httpd\') then',
      target_log_file => "${rsyslog_target}/access_log",
      stop_processing => true
    }
  }
}
