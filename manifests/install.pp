# Package installation
#
class simp_apache::install {
  assert_private()

  package { 'httpd': ensure => 'latest' }

  if $facts['os']['name'] in ['RedHat','CentOS'] {
    if (versioncmp($facts['os']['release']['major'],'7') >= 0) {
      package { 'mod_ldap': ensure => 'latest' }
    }
  }

  if $::simp_apache::ssl {
    package { 'mod_ssl': ensure => 'latest' }
  }
}
