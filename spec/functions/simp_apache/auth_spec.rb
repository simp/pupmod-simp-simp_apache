require 'spec_helper'

describe 'simp_apache::auth' do
  let(:file_auth_hash) {{
    'file' => {
      'enable'    => 'true',
      'user_file' => '/etc/httpd/conf.d/test/.htdigest'
    }
  }}
   
  let(:full_ldap_auth_hash) {{
    'ldap'    => {
      'enable'      => 'true',
      'url'         => ['ldap://server1','ldap://server2'],
      'security'    => 'NONE',
      'binddn'      => 'cn=happy,ou=People,dc=your,dc=domain',
      'bindpw'      => 'birthday',
      'search'      => 'ou=People,dc=your,dc=domain',
      'posix_group' => 'true'
    }
  }}

  let(:minimal_ldap_auth_hash) {{
    'ldap'    => {
      'enable'      => 'true',
      'url'         => ['ldap://server1','ldap://server2'],
      'search'      => 'ou=People,dc=your,dc=domain',
      'posix_group' => 'false'
    }
  }}

  context 'with valid input' do
    it 'generates apache settings for enabled file auth method' do
      expected_output = <<EOM
AuthName "Please Authenticate"
AuthType Basic
AuthBasicProvider file
AuthUserFile /etc/httpd/conf.d/test/.htdigest
EOM
      is_expected.to run.with_params(file_auth_hash).and_return(expected_output.strip)
    end

    it 'generates apache settings for enabled ldap auth method with NONE security' do
      expected_output = <<EOM
AuthName "Please Authenticate"
AuthType Basic
AuthBasicProvider ldap
AuthLDAPUrl "ldap://server1 server2/ou=People,dc=your,dc=domain" NONE
AuthLDAPBindDN "cn=happy,ou=People,dc=your,dc=domain"
AuthLDAPBindPassword 'birthday'
AuthLDAPGroupAttributeIsDN off
AuthLDAPGroupAttribute memberUid
EOM
      is_expected.to run.with_params(full_ldap_auth_hash).and_return(expected_output.strip)
    end

    it 'generates apache settings for enabled ldap auth method with SSL security' do
      input = full_ldap_auth_hash.dup
      input['ldap']['security'] = 'SSL'
      expected_output = <<EOM
AuthName "Please Authenticate"
AuthType Basic
AuthBasicProvider ldap
AuthLDAPUrl "ldap://server1 server2/ou=People,dc=your,dc=domain" SSL
AuthLDAPBindDN "cn=happy,ou=People,dc=your,dc=domain"
AuthLDAPBindPassword 'birthday'
AuthLDAPGroupAttributeIsDN off
AuthLDAPGroupAttribute memberUid
EOM
      is_expected.to run.with_params(input).and_return(expected_output.strip)
    end

    it 'generates apache settings for enabled ldap auth method with TLS security' do
      input = full_ldap_auth_hash.dup
      input['ldap']['security'] = 'TLS'
      expected_output = <<EOM
AuthName "Please Authenticate"
AuthType Basic
AuthBasicProvider ldap
AuthLDAPUrl "ldap://server1 server2/ou=People,dc=your,dc=domain" TLS
AuthLDAPBindDN "cn=happy,ou=People,dc=your,dc=domain"
AuthLDAPBindPassword 'birthday'
AuthLDAPGroupAttributeIsDN off
AuthLDAPGroupAttribute memberUid
EOM
      is_expected.to run.with_params(input).and_return(expected_output.strip)
    end

    it 'generates apache settings for enabled ldap auth method with STARTTLS security' do
      input = full_ldap_auth_hash.dup
      input['ldap']['security'] = 'STARTTLS'
      expected_output = <<EOM
AuthName "Please Authenticate"
AuthType Basic
AuthBasicProvider ldap
AuthLDAPUrl "ldap://server1 server2/ou=People,dc=your,dc=domain" STARTTLS
AuthLDAPBindDN "cn=happy,ou=People,dc=your,dc=domain"
AuthLDAPBindPassword 'birthday'
AuthLDAPGroupAttributeIsDN off
AuthLDAPGroupAttribute memberUid
EOM
      is_expected.to run.with_params(input).and_return(expected_output.strip)
    end

    it 'generates apache settings for more than 1 enabled auth methods' do
      input = file_auth_hash.dup.merge(minimal_ldap_auth_hash)
      expected_output = <<EOM
AuthName "Please Authenticate"
AuthType Basic
AuthBasicProvider file ldap
AuthUserFile /etc/httpd/conf.d/test/.htdigest
AuthLDAPUrl "ldap://server1 server2/ou=People,dc=your,dc=domain"
EOM
      is_expected.to run.with_params(input).and_return(expected_output.strip)
    end

    it 'only generates apache settings for enabled auth methods' do
      input = file_auth_hash.dup.merge(minimal_ldap_auth_hash)
      input['ldap']['enable'] = false
      expected_output = <<EOM
AuthName "Please Authenticate"
AuthType Basic
AuthBasicProvider file
AuthUserFile /etc/httpd/conf.d/test/.htdigest
EOM
      is_expected.to run.with_params(input).and_return(expected_output.strip)
    end

    it 'returns empty string when no enabled auth methods' do
      input = file_auth_hash.dup.merge(minimal_ldap_auth_hash)
      input['ldap']['enable'] = false
      input['file']['enable'] = false
      is_expected.to run.with_params(input).and_return('')
    end
  end

  context 'with invalid input' do
    it 'fails when unsupported auth method is requested'  do
      input = {'dbm'=> {'enable' => true, 'user_file' => '/some/file'}}
      is_expected.to run.with_params(input).and_raise_error(/'dbm' not yet supported/)
    end

    it 'fails when url option for ldap auth method is not present' do
      input = minimal_ldap_auth_hash.dup
      input['ldap'].delete('url')
      is_expected.to run.with_params(input).and_raise_error(/missing option\(s\) 'url'/)
    end

    it 'fails when search option for ldap auth method is not present' do
      input = minimal_ldap_auth_hash.dup
      input['ldap'].delete('search')
      is_expected.to run.with_params(input).and_raise_error(/missing option\(s\) 'search'/)
    end

    it 'fails when posix_group option for ldap auth method is not present' do
      input = minimal_ldap_auth_hash.dup
      input['ldap'].delete('posix_group')
      is_expected.to run.with_params(input).and_raise_error(/missing option\(s\) 'posix_group'/)
    end

    it 'fails when security method for ldap auth method is invalid' do
      input = full_ldap_auth_hash.dup
      input['ldap']['security'] = 'OOPS'
      is_expected.to run.with_params(input).and_raise_error(/Error, 'security'.* Got: 'OOPS'/)
    end

    it 'fails when not all required options for file auth method are present' do
      input = file_auth_hash.dup
      input['file'].delete('user_file')
      is_expected.to run.with_params(input).and_raise_error(/missing option\(s\) 'user_file'/)
    end
  end
end

