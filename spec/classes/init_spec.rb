require 'spec_helper'

describe 'apache' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('apache') }
          it { is_expected.to create_class('apache::conf') }
          it { is_expected.to create_class('apache::ssl') }
          it { is_expected.to create_rsync('site') }
          it { is_expected.to create_selboolean('httpd_can_network_connect') }
        end

        context 'no_rsync_web_root' do
          let(:params){{ :rsync_web_root => false }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('apache') }
          it { is_expected.to create_class('apache::conf') }
          it { is_expected.to create_class('apache::ssl') }
          it { is_expected.not_to create_rsync('site') }
          it { is_expected.to create_selboolean('httpd_can_network_connect') }
        end

        context 'no_ssl' do
          let(:params){{ :ssl => false }} 
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('apache') }
          it { is_expected.to create_class('apache::conf') }
          it { is_expected.not_to create_class('apache::ssl') }
          it { is_expected.to create_rsync('site') }
          it { is_expected.to create_selboolean('httpd_can_network_connect') }
        end
      end
    end
  end
end
