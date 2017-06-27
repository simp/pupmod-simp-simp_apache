module Puppet::Parser::Functions

  newfunction(:apache_auth, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    This takes a hash of arguments related to apache auth settings and returns
    a reasonably formatted set of options.

    Currently, only htaccess and LDAP support are implemented.

    Example:

    apache_auth({
      # Htaccess support
      'file' => {
        'enable'    => 'true',
        'user_file' => '/etc/httpd/conf.d/test/.htdigest'
      }
      'ldap'    => {
        # The LDAP server URI in Apache form.
        'url'         => ['ldap://server1','ldap://server2'],
        # Must be one of 'NONE', 'SSL', 'TLS', or 'STARTTLS'
        'security'    => 'STARTTLS',
        'binddn'      => 'cn=happy,ou=People,dc=your,dc=domain',
        'bindpw'      => 'birthday',
        'search'      => 'ou=People,dc=your,dc=domain',
        # Whether or not your LDAP groups are POSIX groups.
        'posix_group' => 'true'
       }
     }
    )

    Output:
      AuthName "Please Authenticate"
      AuthType Basic
      AuthBasicProvider ldap file
      AuthLDAPUrl "server1 server2/ou=People,dc=your,dc=domain" STARTTLS
      AuthLDAPBindDN "cn=happy,ou=People,dc=your,dc=domain',
      AuthLDAPBindPassword 'birthday'
      AuthLDAPGroupAttributeIsDN off
      AuthLDAPGroupAttribute memberUid
      AuthUserFile /etc/httpd/conf.d/elasticsearch/.htdigest
    ENDHEREDOC

    def self.true?(val)
      return val.to_s.downcase == 'true'
    end

    def self.check_required_opts(required_opts,opts)
      opt_test = required_opts - opts
      if not opt_test.empty? then
        raise Puppet::ParseError, ("apache_auth(): missing options '#{opt_test.join(', ')}'")
      end
    end

    def self.auth_ldap(opts,content)
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

      if opts['security'] then
        if not valid_sec_methods.include?(opts['security']) then
          raise Puppet::ParseError, ("apache_auth(): 'security' must be one of '#{valid_sec_methods.join(', ')}. Got: '#{opts['security']}")
        end
        ldapuri = "#{ldapuri} #{opts['security']}"
      end

      content << "AuthLDAPUrl #{ldapuri}"
      if opts['binddn'] then
        content << "AuthLDAPBindDN \"#{opts['binddn']}\""
        opts['bindpw'] and content << "AuthLDAPBindPassword '#{opts['bindpw'].gsub(/'/, "\\\\'")}'"
      end

      if true?(opts['posix_group']) then
        content << "AuthLDAPGroupAttributeIsDN off"
        content << "AuthLDAPGroupAttribute memberUid"
      end
    end

    def self.auth_file(opts,content)
      required_opts = [ 'user_file' ]

      check_required_opts(required_opts,opts.keys)

      content << "AuthUserFile #{opts['user_file']}"
    end

    function_deprecation([:apache_auth, 'This method is deprecated, please use simp_apache::auth'])

    unless args.length == 1 and args.first.is_a?(Hash) then
      raise Puppet::ParseError, ("apache_auth(): You must supply exactly one Hash argument.")
    end

    args = args.shift

    apache_auth_content = []

    enabled_methods = []
    method_content = []

    args.keys.each do |auth_method|
      not true?(args[auth_method]['enable']) and next

      enabled_methods << auth_method

      begin
        send("auth_#{auth_method}",args[auth_method],method_content)
      rescue NoMethodError => e
        raise Puppet::ParseError, ("apache_auth(): '#{auth_method}' not yet supported")
      end
    end

    # If, for some reason, all methods were disabled, there's nothing to do
    # here.
    if not enabled_methods.empty? then
      apache_auth_content << 'AuthName "Please Authenticate"'
      apache_auth_content << "AuthType Basic"
      apache_auth_content << "AuthBasicProvider #{enabled_methods.join(' ')}"
      apache_auth_content += method_content
    end

    return apache_auth_content.join("\n")
  end
end
