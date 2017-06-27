# Takes a hash of arguments related to Apache 'Limits' settings and
# returns a reasonably formatted set of options.
#
# Currently, host, user ('valid-user' only), ldap-user, and 
# ldap-group limits are supported.  The hash keys for these are
# host limit: 'hosts'
# user limit: 'users'; only applies for 'valid-user', all others assumed
#   LDAP users
# ldap-user limit: 'users'
# ldap-group limit: 'ldap_groups'
#
# Groups of LDAP user primary groups are not supported since you would need
# to know the GID.
#
Puppet::Functions.create_function(:'simp_apache::limits') do

  # @param limits_hash Hash containing desired Apache limits
  # @return [String] Formatted Apache limits settings
  #
  # @example  Host, user and ldap_group limits:
  #
  #   apache_limits(
  #     {
  #       # Set the defaults
  #       # If this is omitted, it just defaults to 'GET'.
  #       'defaults' => [ 'GET', 'POST', 'PUT' ],
  #       # Allow the hosts/subnets below to GET, POST, and PUT to ES.
  #       'hosts'  => {
  #         '1.2.3.4'     => 'defaults',
  #         '3.4.5.6'     => 'defaults',
  #         '10.1.2.0/24' => 'defaults'
  #       },
  #       # You can make a special user 'valid-user' that will translate to
  #       # allowing all valid users.
  #       'users'  => {
  #         # Allow user bob GET, POST, and PUT to ES.
  #         'bob'     => 'defaults',
  #         # Allow user alice GET, POST, PUT, and DELETE to ES.
  #         'alice'   => ['GET','POST','PUT','DELETE']
  #       },
  #       'ldap_groups' => {
  #          # Let the nice users read from ES.
  #          "cn=nice_users,ou=Group,${::basedn}" => 'defaults'
  #        }
  #     }
  #   )
  #
  #   Output:
  #     <Limit DELETE>
  #       Order allow,deny
  #       Require user alice
  #       Satisfy any
  #     </Limit>
  #
  #     <Limit GET>
  #       Order allow,deny
  #       Allow from 1.2.3.4
  #       Allow from 3.4.5.6
  #       Allow from 10.1.2.0/24
  #       Require ldap-user bob
  #       Require ldap-user alice
  #       Require ldap-group cn=nice_users,ou=Group,dc=your,dc=domain
  #       Satisfy any
  #     </Limit>
  #
  #     <Limit POST>
  #       Order allow,deny
  #       Allow from 1.2.3.4
  #       Allow from 3.4.5.6
  #       Allow from 10.1.2.0/24
  #       Require ldap-user bob
  #       Require ldap-user alice
  #       Require ldap-group cn=nice_users,ou=Group,dc=your,dc=domain
  #       Satisfy any
  #     </Limit>
  #
  #     <Limit PUT>
  #       Order allow,deny
  #       Allow from 1.2.3.4
  #       Allow from 3.4.5.6
  #       Allow from 10.1.2.0/24
  #       Require ldap-user bob
  #       Require ldap-user alice
  #       Require ldap-group cn=nice_users,ou=Group,dc=your,dc=domain
  #       Satisfy any
  #     </Limit>
  dispatch :format_limits do
    required_param 'Hash', :limits_hash
  end

  def format_limits(limits_hash)
    limits = limits_hash.dup
    limit_defaults = limits.delete('defaults') || [ 'GET' ]

    limit_collection = {}

   limits.keys.sort.each do |key|
     begin
        send("limit_#{key}",limits[key],limit_collection,limit_defaults)
     rescue NoMethodError => e
       fail("simp_apache::limits(): Error, '#{key}' not yet supported")
     end
    end

    return collect_output(limit_collection)
  end

  def limit_hosts(opts,collection,limit_defaults)
    opts.keys.sort.each do |k|
      v = (opts[k] == 'defaults') ? limit_defaults : Array(opts[k])
      v.each do |oper|
        collection[oper] ||= []

        collection[oper] << "Allow from #{k}"
      end
    end
  end

  #FIXME:  This is super confusing:
  # 1) The 'users' key is used for LDAP users and a special
  #    wild card.  In contrast, the 'ldap_groups' key is
  #    used for LDAP groups.
  # 2) There is no real support for non-LDAP users.
  def limit_users(opts,collection,limit_defaults)
    opts.keys.sort.each do |k|
      v = (opts[k] == 'defaults') ? limit_defaults : Array(opts[k])

      v.each do |oper|
        collection[oper] ||= []

        if k == 'valid-user'
          collection[oper] << 'Require valid-user'
        else
          collection[oper] << "Require ldap-user #{k}"
        end
      end
    end
  end

  def limit_ldap_groups(opts,collection,limit_defaults)
    opts.keys.sort.each do |k|
      v = (opts[k] == 'defaults') ? limit_defaults : Array(opts[k])

      v.each do |oper|
        collection[oper] ||= []

        collection[oper] << "Require ldap-group #{k}"
      end
    end
  end

  def collect_output(collection)
    output = []
    collection.keys.sort.each do |k|
      v = collection[k]
      output << "<Limit #{k}>"
      output << '  Order allow,deny'
      output << "  #{v.sort.join("\n  ")}"
      output << '  Require all denied'
      output << '  Satisfy any'
      output << '</Limit>'
      output << ''
    end

    output.join("\n")
  end
end
