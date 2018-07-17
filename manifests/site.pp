# This adds a 'site' to your configuration.
# In reality, it simply pulls a $name'd template from the templates/sites
# directory under the apache module, or somewhere else if you specify.
# The name should be 'something'.conf and should be an Apache includable
# configuration file.
#
# @example
#  site { 'public': }
#
# @param content
#   Set this to something other than 'base' if you with to write in your own
#   custom content on the fly.
#
define simp_apache::site (
  String $content = 'base'
) {
  include 'simp_apache'

  $_content = $content ? {
    'base'  => template("${module_name}/etc/httpd/conf.d/${name}.conf.erb"),
    default => $content
  }

  file { "/etc/httpd/conf.d/${name}.conf":
    owner   => pick($::simp_apache::conf::user,'root'),
    group   => pick($::simp_apache::conf::group,'apache'),
    mode    => '0640',
    content => $_content,
    notify  => Service['httpd']
  }
}
