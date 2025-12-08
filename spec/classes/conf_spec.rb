require 'spec_helper'

describe 'simp_apache::conf' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        let(:pre_condition) do
          <<~SIMPLIB_IPADDRESSES
            function simplib::ipaddresses {
              ['10.0.2.15','127.0.0.1']
            }
          SIMPLIB_IPADDRESSES
        end

        let(:expected_dir) do
          File.join(File.dirname(__FILE__), 'expected')
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache::conf') }
          it { is_expected.not_to create_iptables__listen__tcp_stateful('allow_http') }
          it { is_expected.not_to create_rsyslog__rule__local('XX_apache_error') }
          it { is_expected.not_to create_rsyslog__rule__local('YY_apache_access') }
          it do
            expected_file = File.join(expected_dir, "httpd.conf_default_el#{facts[:os][:release][:major]}")
            is_expected.to create_file('/etc/httpd/conf/httpd.conf').with(
              owner: 'root',
              group: 'apache',
              mode: '0640',
              content: IO.read(expected_file),
            )
          end
        end

        context 'firewall = true' do
          let(:params) { { 'firewall' => true } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('iptables') }
          it { is_expected.to create_class('simp_apache::conf') }
          it { is_expected.to create_iptables__listen__tcp_stateful('allow_http') }
        end

        context 'syslog = true' do
          let(:params) { { 'syslog' => true } }

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
