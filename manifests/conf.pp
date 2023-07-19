# This class sets up apache.conf.
#
# @param httpd_timeout
#   The Timeout variable. Renamed to not conflict with the Puppet
#   reserved word 'timeout'.
#
# @param httpd_loglevel
#   The LogLevel variable. Renamed to not conflict with the Puppet
#   reserved word 'loglevel'.
#
# @param listen
#   An array of ports upon which Apache should listen.
#
#   NOTE: If you are using an IPv6 with a port, you need to
#     bracket the address
#
# @param firewall
#   Whether or not to use the SIMP IPTables module.
#
# @param syslog
#   Whether or not to use the SIMP Rsyslog module.
#
# @param syslog_target
#   If $syslog is true, store the apache logs at this
#   location.
#
# @param purge
#   Whether or not to purge the configuration directories.
#
# @see The following parameters are referenced in the stock apache
#   documentation
#
# @param keepalive
# @param maxkeepalive
# @param keepalivetimeout
# @param prefork_startservers
# @param prefork_minspareservers
# @param prefork_maxspareservers
# @param prefork_serverlimit
# @param prefork_maxclients
# @param prefork_maxrequestsperchild
# @param worker_startservers
# @param worker_maxclients
# @param worker_minsparethreads
# @param worker_maxsparethreads
# @param worker_threadsperchild
# @param worker_maxrequestsperchild
# @param includes
# @param serveradmin
# @param servername
# @param allowroot
# @param defaulttype
# @param enablemmap
# @param enablesendfile
# @param user
# @param group
# @param logformat
# @param logfacility
#
# @author https://github.com/simp/pupmod-simp-simp_apache/graphs/contributors
#
class simp_apache::conf (
  Integer                                            $httpd_timeout               = 120,
  Boolean                                            $keepalive                   = false,
  Integer                                            $maxkeepalive                = 100,
  Integer                                            $keepalivetimeout            = 15,
  Integer                                            $prefork_startservers        = 8,
  Integer                                            $prefork_minspareservers     = 5,
  Integer                                            $prefork_maxspareservers     = 20,
  Integer                                            $prefork_serverlimit         = 3000,
  Integer                                            $prefork_maxclients          = 3000,
  Integer                                            $prefork_maxrequestsperchild = 4000,
  Integer                                            $worker_startservers         = 2,
  Integer                                            $worker_maxclients           = 3000,
  Integer                                            $worker_minsparethreads      = 25,
  Integer                                            $worker_maxsparethreads      = 75,
  Integer                                            $worker_threadsperchild      = 25,
  Integer                                            $worker_maxrequestsperchild  = 0,
  Array[Variant[Simplib::Host::Port, Simplib::Port]] $listen                      = [80],
  Optional[Array[String]]                            $includes                    = undef,
  String                                             $serveradmin                 = 'root@localhost',
  Optional[String]                                   $servername                  = undef,
  Simplib::Netlist                                   $allowroot                   = ['127.0.0.1','::1'],
  String                                             $defaulttype                 = 'text/plain',
  Boolean                                            $enablemmap                  = true,
  Boolean                                            $enablesendfile              = true,
  String                                             $user                        = 'apache',
  String                                             $group                       = 'apache',
  Simp_apache::LogSeverity                           $httpd_loglevel              = 'warn',
  String                                             $logformat                   = '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
  Simplib::Syslog::LowerFacility                     $logfacility                 = 'local6',
  Boolean                                            $firewall                    = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Boolean                                            $syslog                      = simplib::lookup('simp_options::syslog', { 'default_value' => false }),
  Stdlib::AbsolutePath                               $syslog_target               = '/var/log/httpd',
  Boolean                                            $purge                       = true
) {
  include 'simp_apache'

  # Make sure the networks are all formatted correctly for Apache.
  $l_allowroot = simp_apache::munge_httpd_networks($allowroot)

  file { [
    '/etc/httpd/conf',
    '/etc/httpd/conf.d'
  ]:
    ensure   => 'directory',
    owner    => 'root',
    group    => $group,
    mode     => '0640',
    recurse  => true,
    purge    => $purge,
    force    => $purge,
    checksum => undef
  }

  file { '/etc/httpd/conf/httpd.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => template("${module_name}/etc/httpd/conf/httpd.conf.erb")
  }

  $_modules_target = $facts['os']['hardware'] ? {
    'x86_64' => '/usr/lib64/httpd/modules',
    default  => '/usr/lib/httpd/modules'
  }

  file { $simp_apache::data_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'apache',
    mode   => '0640'
  }

  file { '/etc/httpd/conf/magic':
    ensure  => 'file',
    owner   => 'root',
    group   => 'apache',
    mode    => '0640',
    replace => false,
    content => epp("${module_name}/etc/httpd/conf/magic.epp")
  }

  file { '/etc/httpd/conf.d/welcome.conf': ensure => 'absent' }

  file { '/etc/mime.types':
    owner => 'root',
    group => 'root',
    mode  => '0644'
  }

  file { '/etc/httpd/logs':
    ensure => 'symlink',
    target => '/var/log/httpd',
    force  => true
  }

  file { '/etc/httpd/modules':
    ensure => 'symlink',
    target =>  $_modules_target,
    force  => true
  }

  file { '/etc/httpd/run':
    ensure => 'symlink',
    target => '/var/run/httpd',
    force  => true
  }

  file { '/var/log/httpd':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700'
  }

  file { 'httpd_modules':
    ensure => 'directory',
    path   => $_modules_target,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  if $firewall {
    include 'iptables'

    iptables::listen::tcp_stateful { 'allow_http':
      order        => 11,
      trusted_nets => $l_allowroot,
      dports       => $listen
    }
  }

  if $syslog  {
    include '::rsyslog'
    rsyslog::rule::local { 'XX_apache_error':
      rule            => '$programname == \'httpd\' and $syslogseverity-text == \'err\'',
      target_log_file => "${syslog_target}/error_log",
      stop_processing => true
    }
    rsyslog::rule::local { 'YY_apache_access':
      rule            => '$programname == \'httpd\'',
      target_log_file => "${syslog_target}/access_log",
      stop_processing => true
    }
  }
}
