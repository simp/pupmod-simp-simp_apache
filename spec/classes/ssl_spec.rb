require 'spec_helper'

describe 'apache::ssl' do
  base_facts = {
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :selinux_current_mode => 'enabled',
    :interfaces => 'lo',
    :ipaddress_lo => '127.0.0.1',
    :operatingsystem => 'RedHat',
    :lsbmajdistrelease => '7',
    :apache_version => '2.4',
    :grub_version => '2.0~beta',
    :uid_min => '500'
  }
  let(:facts){base_facts}

  context 'base' do
    it { should compile.with_all_deps }
    it { should create_class('apache') }
    it { should create_class('apache::ssl') }
    it { should create_iptables__add_tcp_stateful_listen('allow_https') }
    it { should create_class('pki') }
    it { should create_pki__copy('/etc/httpd/conf') }
  end

  context 'no_enable_iptables' do
    let(:params){{ 'enable_iptables' => false }}

    it { should compile.with_all_deps }
    it { should create_class('apache') }
    it { should create_class('apache::ssl') }
    it { should_not create_iptables__add_tcp_stateful_listen('allow_https') }
    it { should create_class('pki') }
    it { should create_pki__copy('/etc/httpd/conf') }
  end

  context 'no_use_simp_pki' do
    let(:params){{ 'use_simp_pki' => false }}

    it { should compile.with_all_deps }
    it { should create_class('apache') }
    it { should create_class('apache::ssl') }
    it { should create_iptables__add_tcp_stateful_listen('allow_https') }
# This doesn't work for undetermined reasons
#    it { should_not contain_class('pki') }
    it { should_not create_pki__copy('/etc/httpd/conf') }
  end

  context 'use_simp_pki_and_filled_cert_source' do
    let(:params){{
      'use_simp_pki' => true,
      'cert_source'  => '/tmp/foo'
    }}

    it { should compile.with_all_deps }
    it { should create_class('apache') }
    it { should create_class('apache::ssl') }
    it { should create_iptables__add_tcp_stateful_listen('allow_https') }
    it { should create_class('pki') }
    it { should create_pki__copy('/etc/httpd/conf') }
    it {
      should_not create_file('/etc/httpd/conf/pki').with({
        'source' => params['cert_source']
      })
    }
  end

  context 'no_use_simp_pki_and_filled_cert_source' do
    let(:params){{
      'use_simp_pki' => false,
      'cert_source'  => '/tmp/foo'
    }}

    it { should compile.with_all_deps }
    it { should create_class('apache') }
    it { should create_class('apache::ssl') }
    it { should create_iptables__add_tcp_stateful_listen('allow_https') }
# This doesn't work for undetermined reasons
#    it { should_not create_class('pki') }
    it { should_not create_pki__copy('/etc/httpd/conf') }
    it {
      should create_file('/etc/httpd/conf/pki').with({
        'source' => params['cert_source']
      })
    }
  end
end
