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
          it { is_expected.to_not create_pki__copy('simp_apache') }
          it { is_expected.to_not contain_class('haveged') }
        end

        context 'firewall = true' do
          let(:params){{ :firewall => true }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to create_iptables__listen__tcp_stateful('allow_https') }
          it { is_expected.to_not create_class('pki') }
          it { is_expected.to_not create_pki__copy('simp_apache') }
        end

        context 'pki = simp' do
          let(:params){{ :pki => 'simp' }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to_not create_iptables__listen__tcp_stateful('allow_https') }
          it { is_expected.to contain_class('pki') }
          it { is_expected.to create_pki__copy('simp_apache') }
          it { is_expected.to create_file('/etc/pki/simp_apps/simp_apache/x509') }
        end

        context 'with haveged = false' do
          let(:params) {{:haveged => false}}
          it { is_expected.to_not contain_class('haveged') }
        end

      end
    end
  end
end
