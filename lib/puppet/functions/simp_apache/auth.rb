# Takes a hash of arguments related to Apache 'Auth' settings and
# returns a reasonably formatted set of options.
#
# Currently, only htaccess and LDAP support are implemented.
Puppet::Functions.create_function(:'simp_apache::auth') do

  # @param auth_hash Hash containing desired Apache authentication
  #    methods and relevant parameters as key value pairs. The
  #    key is the authentication method, while the corresponding
  #    value is a Hash of relevant parameters.
  # @return [String] Formatted Apache authentication settings
  #
  # @example Htaccess and LDAP authentication:
  #   simp_apache::auth({
  #     # Htaccess support
  #     'file' => {
  #       'enable'    => 'true',
  #       'user_file' => '/etc/httpd/conf.d/test/.htdigest'
  #     }
  #     'ldap'    => {
  #       'enable'      => 'true',
  #       # The LDAP server URI in Apache form.
  #       'url'         => ['ldap://server1','ldap://server2'],
  #       # Must be one of 'NONE', 'SSL', 'TLS', or 'STARTTLS'
  #       'security'    => 'STARTTLS',
  #       'binddn'      => 'cn=happy,ou=People,dc=your,dc=domain',
  #       'bindpw'      => 'birthday',
  #       'search'      => 'ou=People,dc=your,dc=domain',
  #       # Whether or not your LDAP groups are POSIX groups.
  #       'posix_group' => 'true'
  #      }
  #    }
  #   )
  #
  #   Output:
  #     AuthName "Please Authenticate"
  #     AuthType Basic
  #     AuthBasicProvider ldap file
  #     AuthLDAPUrl "ldap://server1 server2/ou=People,dc=your,dc=domain" STARTTLS
  #     AuthLDAPBindDN "cn=happy,ou=People,dc=your,dc=domain',
  #     AuthLDAPBindPassword 'birthday'
  #     AuthLDAPGroupAttributeIsDN off
  #     AuthLDAPGroupAttribute memberUid
  #     AuthUserFile /etc/httpd/conf.d/elasticsearch/.htdigest
  #
  dispatch :format_auth do
    required_param 'Hash', :auth_hash
  end

  def format_auth(auth_hash)
    apache_auth_content = []

    enabled_methods = []
    method_content = []

    auth_hash.keys.each do |auth_method|
      next unless true?(auth_hash[auth_method]['enable'])

      begin
        send("auth_#{auth_method}", auth_hash[auth_method], method_content)
        enabled_methods << auth_method
      rescue NoMethodError => e
        fail("simp_apache::auth(): Error, '#{auth_method}' not yet supported")
      end
    end

    # If, for some reason, all methods were disabled, there's nothing to do
    # here.
    unless enabled_methods.empty?
      apache_auth_content << 'AuthName "Please Authenticate"'
      apache_auth_content << "AuthType Basic"
      apache_auth_content << "AuthBasicProvider #{enabled_methods.join(' ')}"
      apache_auth_content += method_content
    end

    return apache_auth_content.join("\n")
  end

  def true?(val)
    return val.to_s.downcase == 'true'
  end

  def check_required_opts(required_opts,opts)
    opt_test = required_opts - opts
    unless opt_test.empty?
      fail("simp_apache::auth(): Error, missing option(s) '#{opt_test.join(', ')}'")
    end
  end

  def auth_ldap(opts,content)
    required_opts = [
      'url',
      'search',
      'posix_group'
    ]

    valid_sec_methods = [
      'NONE',
      'SSL',
      'TLS',
      'STARTTLS'
    ]

    check_required_opts(required_opts,opts.keys)

    ldapuri = 'ldap://' + Array(opts['url']).join(' ').gsub(/ldap:\/\//,'')
    ldapuri = ldapuri + '/' + opts['search']
    ldapuri = '"' + ldapuri + '"'

    if opts['security']
      unless valid_sec_methods.include?(opts['security'])
        fail("simp_apache::auth(): Error, 'security' must be one of {#{valid_sec_methods.join(', ')}}. Got: '#{opts['security']}'")
      end
      ldapuri = "#{ldapuri} #{opts['security']}"
    end

    content << "AuthLDAPUrl #{ldapuri}"
    if opts['binddn']
      content << "AuthLDAPBindDN \"#{opts['binddn']}\""
      content << "AuthLDAPBindPassword '#{opts['bindpw'].gsub(/'/, "\\\\'")}'" if opts['bindpw']
    end

    if true?(opts['posix_group'])
      content << "AuthLDAPGroupAttributeIsDN off"
      content << "AuthLDAPGroupAttribute memberUid"
    end
  end

  def auth_file(opts,content)
    required_opts = [ 'user_file' ]

    check_required_opts(required_opts,opts.keys)

    content << "AuthUserFile #{opts['user_file']}"
  end
end
