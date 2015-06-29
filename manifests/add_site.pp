# == Define: apache::add_site
#
# This adds a 'site' to your configuration.
# In reality, it simply pulls a $name'd template from the templates/sites
# directory under the apache module, or somewhere else if you specify.
# The name should be 'something'.conf and should be an Apache includable
# configuration file.
#
# _Example_
#
#  add_site { 'public': }
#
# == Parameters
#
# [*content*]
#   Set this to something other than 'base' if you with to write in your own
#   custom content on the fly.
#
#
define apache::add_site (
  $content = 'base'
) {
  include 'apache'

  file { "/etc/httpd/conf.d/${name}.conf":
    owner   => hiera('apache::conf::group','root'),
    group   => hiera('apache::conf::group','apache'),
    mode    => '0640',
    content => $content ? {
      'base'  => template("apache/etc/httpd/conf.d/${name}.conf.erb"),
      default => $content
    },
    notify  => Service['httpd']
  }
}
