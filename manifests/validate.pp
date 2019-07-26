# @summary Should be used as input to `validate_deep_hash` when managing `ldap`
# or `limits` ACLs
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp_apache::validate {
  $method_acl = {
    'method' => {
      'file' => {
        'enable'    => '^true|false$',
        'user_file' => '^/.*'
      },
      'ldap' => {
        'enable'      => '^true|false$',
        'url'         => nil,
        'security'    => '^SSL|TLS|STARTTLS$',
        'binddn'      => '^(.+=.+,?)*',
        'bindpw'      => nil,
        'search'      => '^(.+=.+,?)*',
        'posix_group' => true
      }
    },
    'limits' => {
      'defaults'    => nil,
      'hosts'       => nil,
      'users'       => nil,
      'ldap_groups' => nil
    }
  }
}
