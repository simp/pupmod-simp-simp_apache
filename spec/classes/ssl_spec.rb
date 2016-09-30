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
          it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_https') }
          it { is_expected.to create_class('pki') }
          it { is_expected.to create_pki__copy('/etc/httpd/conf') }
          it { is_expected.to contain_class('haveged') }
        end

        context 'no_enable_iptables' do
          let(:params){{ 'enable_iptables' => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.not_to create_iptables__add_tcp_stateful_listen('allow_https') }
          it { is_expected.to create_class('pki') }
          it { is_expected.to create_pki__copy('/etc/httpd/conf') }
        end

        context 'no_use_simp_pki' do
          let(:params){{ 'use_simp_pki' => false }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_https') }
          # This doesn't work for undetermined reasons
          #    it { should_not contain_class('pki') }
          it { is_expected.not_to create_pki__copy('/etc/httpd/conf') }
        end

        context 'use_simp_pki_and_filled_cert_source' do
          let(:params){{
            'use_simp_pki' => true,
            'cert_source'  => '/tmp/foo'
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_https') }
          it { is_expected.to create_class('pki') }
          it { is_expected.to create_pki__copy('/etc/httpd/conf') }
          it {
            is_expected.not_to create_file('/etc/httpd/conf/pki').with({
              'source' => params['cert_source']
            })
          }
        end

        context 'no_use_simp_pki_and_filled_cert_source' do
          let(:params){{
            'use_simp_pki' => false,
            'cert_source'  => '/tmp/foo'
          }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to create_iptables__add_tcp_stateful_listen('allow_https') }
          # This doesn't work for undetermined reasons
          #    it { should_not create_class('pki') }
          it { is_expected.not_to create_pki__copy('/etc/httpd/conf') }
          it {
            is_expected.to create_file('/etc/httpd/conf/pki').with({
              'source' => params['cert_source']
            })
          }
        end

        context 'with use_haveged => false' do
          let(:params) {{:use_haveged => false}}
          it { is_expected.to_not contain_class('haveged') }
        end

        context 'with invalid input' do
          let(:params) {{:use_haveged => 'invalid_input'}}
          it 'with use_haveged as a string' do
            expect {
              is_expected.to compile
            }.to raise_error(RSpec::Expectations::ExpectationNotMetError,/invalid_input" is not a boolean/)
          end
        end

      end
    end
  end
end
