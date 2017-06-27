require 'spec_helper'

describe 'simp_apache::limits' do
  let(:limits_hash) {{
    'defaults' => [ 'GET', 'POST', 'PUT' ],
    'hosts'  => {
      '1.2.3.4'     => 'defaults',
      '3.4.5.6'     => ['GET', 'POST'],
      '10.1.2.0/24' => 'defaults'
    },
    'users'  => {
      'bob'        => 'defaults',
      'alice'      => ['GET','POST','PUT','DELETE']
    },
    'ldap_groups' => {
      'cn=basic_users,ou=Group,dc=your,dc=domain' => 'defaults',
      'cn=admin_users,ou=Group,dc=your,dc=domain' => ['GET','POST','PUT','DELETE']
    }
  }}
   
  context 'with valid input' do
    it 'generates apache limits using defaults' do
      expected_output = <<EOM
<Limit DELETE>
  Order allow,deny
  Require ldap-group cn=admin_users,ou=Group,dc=your,dc=domain
  Require ldap-user alice
  Require all denied
  Satisfy any
</Limit>

<Limit GET>
  Order allow,deny
  Allow from 1.2.3.4
  Allow from 10.1.2.0/24
  Allow from 3.4.5.6
  Require ldap-group cn=admin_users,ou=Group,dc=your,dc=domain
  Require ldap-group cn=basic_users,ou=Group,dc=your,dc=domain
  Require ldap-user alice
  Require ldap-user bob
  Require all denied
  Satisfy any
</Limit>

<Limit POST>
  Order allow,deny
  Allow from 1.2.3.4
  Allow from 10.1.2.0/24
  Allow from 3.4.5.6
  Require ldap-group cn=admin_users,ou=Group,dc=your,dc=domain
  Require ldap-group cn=basic_users,ou=Group,dc=your,dc=domain
  Require ldap-user alice
  Require ldap-user bob
  Require all denied
  Satisfy any
</Limit>

<Limit PUT>
  Order allow,deny
  Allow from 1.2.3.4
  Allow from 10.1.2.0/24
  Require ldap-group cn=admin_users,ou=Group,dc=your,dc=domain
  Require ldap-group cn=basic_users,ou=Group,dc=your,dc=domain
  Require ldap-user alice
  Require ldap-user bob
  Require all denied
  Satisfy any
</Limit>
EOM
      is_expected.to run.with_params(limits_hash).and_return(expected_output)
    end

    it 'generates apache limits using the default for non-specified defaults key' do
      limits_hash_no_defaults = limits_hash.dup
      limits_hash_no_defaults.delete('defaults')
      expected_output = <<EOM
<Limit DELETE>
  Order allow,deny
  Require ldap-group cn=admin_users,ou=Group,dc=your,dc=domain
  Require ldap-user alice
  Require all denied
  Satisfy any
</Limit>

<Limit GET>
  Order allow,deny
  Allow from 1.2.3.4
  Allow from 10.1.2.0/24
  Allow from 3.4.5.6
  Require ldap-group cn=admin_users,ou=Group,dc=your,dc=domain
  Require ldap-group cn=basic_users,ou=Group,dc=your,dc=domain
  Require ldap-user alice
  Require ldap-user bob
  Require all denied
  Satisfy any
</Limit>

<Limit POST>
  Order allow,deny
  Allow from 3.4.5.6
  Require ldap-group cn=admin_users,ou=Group,dc=your,dc=domain
  Require ldap-user alice
  Require all denied
  Satisfy any
</Limit>

<Limit PUT>
  Order allow,deny
  Require ldap-group cn=admin_users,ou=Group,dc=your,dc=domain
  Require ldap-user alice
  Require all denied
  Satisfy any
</Limit>
EOM
      is_expected.to run.with_params(limits_hash_no_defaults).and_return(expected_output)
    end

    it 'generates apache wildcard user limits' do
      valid_user_limits_hash = {'users' => {'valid-user' => 'GET' } }
      expected_output = <<EOM
<Limit GET>
  Order allow,deny
  Require valid-user
  Require all denied
  Satisfy any
</Limit>
EOM
      is_expected.to run.with_params(valid_user_limits_hash).and_return(expected_output)
    end

    it 'returns empty string when no limits are specified' do
      is_expected.to run.with_params({}).and_return('')
    end
  end

  context 'with invalid input' do
    it 'fails when unsupported limit is requested'  do
      input = {'oops'=> {'user1' => 'defautls'}}
      is_expected.to run.with_params(input).and_raise_error(/'oops' not yet supported/)
    end
  end
end
