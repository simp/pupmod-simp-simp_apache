# This class sets up apache.conf.
#
# @NOTE: If a parameter is not listed here then it is part of the
# standard Apache configuration set and the stock Apache documentation
# should be referenced.
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
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp_apache::conf (
  Integer                        $httpd_timeout               = 120,
  Boolean                        $keepalive                   = false,
  Integer                        $maxkeepalive                = 100,
  Integer                        $keepalivetimeout            = 15,
  Integer                        $prefork_startservers        = 8,
  Integer                        $prefork_minspareservers     = 5,
  Integer                        $prefork_maxspareservers     = 20,
  Integer                        $prefork_serverlimit         = 3000,
  Integer                        $prefork_maxclients          = 3000,
  Integer                        $prefork_maxrequestsperchild = 4000,
  Integer                        $worker_startservers         = 2,
  Integer                        $worker_maxclients           = 3000,
  Integer                        $worker_minsparethreads      = 25,
  Integer                        $worker_maxsparethreads      = 75,
  Integer                        $worker_threadsperchild      = 25,
  Integer                        $worker_maxrequestsperchild  = 0,
  Array[Simplib::Port]           $listen                      = [80],
  Optional[Array[String]]        $includes                    = undef,
  String                         $serveradmin                 = 'root@localhost',
  Optional[String]               $servername                  = undef,
  Simplib::Netlist               $allowroot                   = ['127.0.0.1','::1'],
  String                         $defaulttype                 = 'text/plain',
  Boolean                        $enablemmap                  = true,
  Boolean                        $enablesendfile              = true,
  String                         $user                        = 'apache',
  String                         $group                       = 'apache',
  Simp_apache::LogSeverity       $httpd_loglevel              = 'warn',
  String                         $logformat                   = '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
  Simplib::Syslog::LowerFacility $logfacility                 = 'local6',
  Boolean                        $firewall                    = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Boolean                        $syslog                      = simplib::lookup('simp_options::syslog', { 'default_value' => false }),
  Stdlib::AbsolutePath           $syslog_target               = '/var/log/httpd',
  Boolean                        $purge                       = true
) {
  include '::simp_apache'

  # Make sure the networks are all formatted correctly for Apache.
  $l_allowroot = simp_apache::munge_httpd_networks($allowroot)

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
