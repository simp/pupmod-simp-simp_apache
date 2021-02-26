# Control the Apache service
#
# @param manage
#   Whether or not to manage the service
#
#   If set to `false`, you may need to add the service name to
#   `svckill::ignore` if you are in enforcing mode.
#
# @param service_name
#   The name of the service to manage
#
# @param ensure
#   The state that the service should be in
#
# @param enable
#   Whether or not to enable the daemon
#
# @param hasstatus
#   Whether or not the service has a 'status' command
#
# @param hasrestart
#   If set to `true` then the contents of `$restart` will be ignored
#
# @param restart
#   A specific command to use to restart the daemon
#
#   * Ignored if `$hasrestart` is set to `true`
#   * The `reload || restart` is in place to try to force a clean restart if a
#     reload fails to do the job.
#
class simp_apache::service (
  Boolean   $manage       = true,
  String[1] $service_name = 'httpd',
  String[1] $ensure       = 'running',
  Boolean   $enable       = true,
  Boolean   $hasstatus    = true,
  Boolean   $hasrestart   = false,
  String[1] $restart      = '/usr/bin/systemctl reload httpd.service || /usr/bin/systemctl restart httpd.service'
) {
  if $manage {
    if $hasrestart {
      $_restart = undef
    }
    else {
      $_restart = $restart
    }

    service { $service_name:
      ensure     => $ensure,
      enable     => $enable,
      hasrestart => $hasrestart,
      hasstatus  => $hasstatus,
      restart    => $_restart
    }
  }
}
