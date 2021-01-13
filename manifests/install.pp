# @summary Apache package management
#
# @param httpd_ensure
#   The ensure status the httpd package
#
# @param mod_ldap_ensure
#   The ensure status the mod_ldap package
#
# @param mod_ssl_ensure
#   The ensure status the mod_ssl package
#
class simp_apache::install (
  String $httpd_ensure    = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  String $mod_ldap_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  String $mod_ssl_ensure  = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {
  assert_private()

  package { 'httpd':
    ensure => $httpd_ensure
  }

  if $simp_apache::ssl {
    package { 'mod_ssl':
      ensure => $mod_ssl_ensure
    }
  }
}
