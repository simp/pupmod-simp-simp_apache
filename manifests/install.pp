# == Class: simp_apache::install
#
# Package installation
#
class simp_apache::install {

  assert_private()


  package { 'httpd': ensure => 'latest' }

  if $::operatingsystem in ['RedHat','CentOS'] {
    if (versioncmp($::operatingsystemmajrelease,'7') >= 0) {
      package { 'mod_ldap': ensure => 'latest' }
    }
  }

  if $::simp_apache::ssl {
    package { 'mod_ssl': ensure => 'latest' }
  }
}
