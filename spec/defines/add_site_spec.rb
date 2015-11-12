require 'spec_helper'

describe 'apache::add_site' do
  let(:facts) {{
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :interfaces => 'lo',
    :ipaddress_lo => '127.0.0.1',
    :operatingsystem => 'RedHat',
    :operatingsystemmajrelease => '7',
    :apache_version => '2.4',
    :grub_version => '2.0~beta',
    :uid_min => '500',
    :selinux_current_mode => 'enabled'
  }}
  let(:title) {'test'}
  let(:params) {{ :content => 'test' }}

  it { should create_class('apache') }

  it { should contain_file("/etc/httpd/conf.d/#{title}.conf").with_content('test') }
end
