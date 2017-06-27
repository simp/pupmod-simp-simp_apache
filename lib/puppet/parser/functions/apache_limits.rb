module Puppet::Parser::Functions

  newfunction(:apache_limits, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    This takes a hash of arguments related to apache 'Limits' settings and
    returns a reasonably formatted set of options.

    Currently, host, user, ldap_user, and ldap_group limits are supported.

    Groups of LDAP user primary groups are not supported since you would need
    to know the GID.

    Example:

    apache_limits(
      {
        # Set the defaults
        # If this is omitted, it just defaults to 'GET'.
        'defaults' => [ 'GET', 'POST', 'PUT' ],
        # Allow the hosts/subnets below to GET, POST, and PUT to ES.
        'hosts'  => {
          '1.2.3.4'     => 'defaults',
          '3.4.5.6'     => 'defaults',
          '10.1.2.0/24' => 'defaults'
        },
        # You can make a special user 'valid-user' that will translate to
        # allowing all valid users.
        'users'  => {
          # Allow user bob GET, POST, and PUT to ES.
          'bob'     => 'defaults',
          # Allow user alice GET, POST, PUT, and DELETE to ES.
          'alice'   => ['GET','POST','PUT','DELETE']
        },
        'ldap_groups' => {
           # Let the nice users read from ES.
           "cn=nice_users,ou=Group,${::basedn}" => 'defaults'
         }
      }
    )

    Output:
      <Limit GET>
        Order allow,deny
        Allow from 1.2.3.4
        Allow from 3.4.5.6
        Allow from 10.1.2.0/24
        Require user bob
        Require user alice
        Require group cn=nice_users,ou=Group,dc=your,dc=domain
        Satisfy any
      </Limit>

      <Limit POST>
        Order allow,deny
        Allow from 1.2.3.4
        Allow from 3.4.5.6
        Allow from 10.1.2.0/24
        Require user bob
        Require user alice
        Require group cn=nice_users,ou=Group,dc=your,dc=domain
        Satisfy any
      </Limit>

      <Limit PUT>
        Order allow,deny
        Allow from 1.2.3.4
        Allow from 3.4.5.6
        Allow from 10.1.2.0/24
        Require user bob
        Require user alice
        Require group cn=nice_users,ou=Group,dc=your,dc=domain
        Satisfy any
      </Limit>

      <Limit DELETE>
        Order allow,deny
        Require user alice
        Satisfy any
      </Limit>
    ENDHEREDOC

    def self.limit_hosts(opts,collection)
      opts.keys.sort.each do |k|
        v = opts[k]

        v == 'defaults' and v = @limits_defaults

        v.each do |oper|
          collection[oper] ||= []

          collection[oper] << "Allow from #{k}"
        end
      end
    end

    def self.limit_users(opts,collection)
      opts.keys.sort.each do |k|
        v = opts[k]
        v == 'defaults' and v = @limits_defaults

        v.each do |oper|
          collection[oper] ||= []

          if k == 'valid-user' then
            collection[oper] << "Require valid-user"
          else
            collection[oper] << "Require ldap-user #{k}"
          end
        end
      end
    end

    def self.limit_ldap_groups(opts,collection)
      opts.keys.sort.each do |k|
        v = opts[k]
        v == 'defaults' and v = @limits_defaults

        v.each do |oper|
          collection[oper] ||= []

          collection[oper] << "Require ldap-group #{k}"
        end
      end
    end

    def self.collect_output(collection)
      output = []
      collection.keys.sort.each do |k|
        v = collection[k]
        output << "<Limit #{k}>"
        output << "  Order allow,deny"
        output << "  #{v.join("\n  ")}"
        output << "  Require all denied"
        output << "  Satisfy any"
        output << "</Limit>"
      end

      output.join("\n")
    end

    function_deprecation([:apache_limits, 'This method is deprecated, please use simp_apache::limits'])

    unless args.count == 1 and args.first.is_a?(Hash) then
      raise Puppet::ParseError, ("apache_limits(): You must supply exactly one Hash argument.")
    end

    args = args.shift.dup

    @limits_defaults = args.delete('defaults') || [ 'GET' ]

    limit_collection = {}

    begin
      args.keys.sort.each do |key|
        send("limit_#{key}",args[key],limit_collection)
      end
    rescue NoMethodError => e
      raise Puppet::ParseError, ("apache_limits(): '#{auth_method}' not yet supported")
    end

    return collect_output(limit_collection)
  end
end
