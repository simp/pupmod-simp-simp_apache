require 'spec_helper'

describe 'apache::conf' do
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

  it { should compile.with_all_deps }
  it { should create_class('apache::conf') }
  it { should create_iptables__add_tcp_stateful_listen('allow_http') }
  it { should create_rsyslog__add_rule('10apache') }

  context 'no_iptables' do
    let(:params){{ 'enable_iptables' => false }}

    it { should compile.with_all_deps }
    it { should create_class('apache::conf') }
    it { should_not create_iptables__add_tcp_stateful_listen('allow_http') }
    it { should create_rsyslog__add_rule('10apache') }
  end

  context 'no_enable_rsyslog' do
    let(:params){{ 'enable_rsyslog' => false }}

    it { should compile.with_all_deps }
    it { should create_class('apache::conf') }
    it { should create_iptables__add_tcp_stateful_listen('allow_http') }
    it { should_not create_rsyslog__add_rule('10apache') }
  end
end
