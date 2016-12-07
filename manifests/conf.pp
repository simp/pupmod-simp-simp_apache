# == Class: simp_apache::conf
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
# [*firewall*]
#   Type: Boolean
#   Whether or not to use the SIMP IPTables module.
#
# [*syslog*]
#   Type: Boolean
#   Whether or not to use the SIMP Rsyslog module.
#
# [*syslog_target*]
#   Type: Absolute Path
#   If $syslog is true, store the apache logs at this
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
class simp_apache::conf (
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
  $firewall = lookup('simp_options::firewall',  { 'default_value' => false, 'value_type' => Boolean}),
  $syslog  = lookup('simp_options::syslog',  { 'default_value' => false, 'value_type' => Boolean}),
  $syslog_target = '/var/log/httpd',
  $purge = true
) {
  include '::simp_apache'

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
  validate_bool($firewall)
  validate_bool($syslog)
  validate_absolute_path($syslog_target)
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
    checksum => undef
  }

  file { '/etc/httpd/conf/httpd.conf':
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => template("${module_name}/etc/httpd/conf/httpd.conf.erb"),
    notify  => Service['httpd']
  }

  if $firewall {
    include '::iptables'

    iptables::add_tcp_stateful_listen { 'allow_http':
      order        => '11',
      trusted_nets => $l_allowroot,
      dports       => $listen
    }
  }

  if $syslog  {
    include '::rsyslog'
    rsyslog::rule::local { 'XX_apache_error':
      rule            => 'if ($programname == \'httpd\' and $syslogseverity-text == \'err\') then',
      target_log_file => "${syslog_target}/error_log",
      stop_processing => true
    }
    rsyslog::rule::local { 'YY_apache_access':
      rule            => 'if ($programname == \'httpd\') then',
      target_log_file => "${syslog_target}/access_log",
      stop_processing => true
    }
  }
}
