require 'spec_helper'

describe 'apache::conf' do
  base_facts = {
    :fqdn => 'test.host.net',
    :hardwaremodel => 'x86_64',
    :selinux_current_mode => 'enabled',
    :interfaces => 'lo',
    :ipaddress_lo => '127.0.0.1',
    :operatingsystem => 'RedHat',
    :operatingsystemmajrelease => '7',
    :apache_version => '2.4',
    :grub_version => '2.0~beta',
    :uid_min => '500'
  }
  let(:facts){base_facts}

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('apache::conf') }
  it { is_expected.not_to create_iptables__add_tcp_stateful_listen('allow_http') }
# Once the SIMP globals change for SIMPv6, these will actually be the defaults.
#  it { should_not create_rsyslog__rule__local('10apache_error') }
#  it { should_not create_rsyslog__rule__local('10apache_access') }
  it { is_expected.to create_rsyslog__rule__local('10apache_error') }
  it { is_expected.to create_rsyslog__rule__local('10apache_access') }

  context 'enable_iptables' do
    let(:params){{ 'enable_iptables' => true }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('iptables') }
    it { is_expected.to create_class('apache::conf') }
    it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_http') }
  end

  context 'enable_logging' do
    let(:params){{ 'enable_logging' => true }}

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('apache::conf') }
    it { is_expected.to create_class('rsyslog') }
    it { is_expected.to create_rsyslog__rule__local('10apache_error') }
    it { is_expected.to create_rsyslog__rule__local('10apache_access') }
  end
end
