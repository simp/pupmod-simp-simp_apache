require 'spec_helper'

describe 'simp_apache::conf' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache::conf') }
          it { is_expected.not_to create_iptables__listen__tcp_stateful('allow_http') }
          it { is_expected.to_not create_rsyslog__rule__local('XX_apache_error') }
          it { is_expected.to_not create_rsyslog__rule__local('YY_apache_access') }
        end

        context 'firewall = true' do
          let(:params){{ 'firewall' => true }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('iptables') }
          it { is_expected.to create_class('simp_apache::conf') }
          it { is_expected.to create_iptables__listen__tcp_stateful('allow_http') }
        end

        context 'syslog = true' do
          let(:params){{ 'syslog' => true }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache::conf') }
          it { is_expected.to create_class('rsyslog') }
          it { is_expected.to create_rsyslog__rule__local('XX_apache_error') }
          it { is_expected.to create_rsyslog__rule__local('YY_apache_access') }
        end
      end
    end
  end
end
