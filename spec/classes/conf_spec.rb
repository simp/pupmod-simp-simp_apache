require 'spec_helper'

describe 'apache::conf' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('apache::conf') }
          it { is_expected.not_to create_iptables__add_tcp_stateful_listen('allow_http') }
          # Once the SIMP globals change for SIMPv6, these will actually be the defaults.
          #  it { should_not create_rsyslog__rule__local('10apache_error') }
          #  it { should_not create_rsyslog__rule__local('10apache_access') }
          it { is_expected.to create_rsyslog__rule__local('10apache_error') }
          it { is_expected.to create_rsyslog__rule__local('10apache_access') }
        end

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
    end
  end
end
