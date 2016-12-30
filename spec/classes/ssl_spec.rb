require 'spec_helper'

describe 'simp_apache::ssl' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to_not create_iptables__listen__tcp_stateful('allow_https') }
          it { is_expected.to_not create_class('pki') }
          it { is_expected.to_not create_pki__copy('/etc/httpd/conf') }
          it { is_expected.to_not contain_class('haveged') }
        end

        context 'firewall = true' do
          let(:params){{ :firewall => true }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to create_iptables__listen__tcp_stateful('allow_https') }
          it { is_expected.to_not create_class('pki') }
          it { is_expected.to_not create_pki__copy('/etc/httpd/conf') }
        end

        context 'pki = true' do
          let(:params){{ :pki => true }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to_not create_iptables__listen__tcp_stateful('allow_https') }
          it { is_expected.to create_class('pki') }
          it { is_expected.to create_pki__copy('/etc/httpd/conf') }
        end

        context 'pki = true and filled app_pki_cert_source' do
          let(:params){{
            :pki => true, :app_pki_cert_source  => '/tmp/foo'
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to_not create_iptables__listen__tcp_stateful('allow_https') }
          it { is_expected.to create_class('pki') }
          it { is_expected.to create_pki__copy('/etc/httpd/conf') }
          it { is_expected.to create_file('/etc/httpd/conf/pki').with({
              'source' => nil
            })
          }
        end

        context 'pki = false and filled app_pki_cert_source' do
          let(:params){{
            :app_pki_cert_source  => '/tmp/foo'
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to_not create_iptables__listen__tcp_stateful('allow_https') }
          it { is_expected.to_not create_class('pki') }
          it { is_expected.to_not create_pki__copy('/etc/httpd/conf') }
          it {
            is_expected.to create_file('/etc/httpd/conf/pki').with({
              'source' => '/tmp/foo'
            })
          }
        end

        context 'with haveged = false' do
          let(:params) {{:haveged => false}}
          it { is_expected.to_not contain_class('haveged') }
        end

      end
    end
  end
end
