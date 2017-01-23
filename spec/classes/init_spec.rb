require 'spec_helper'

shared_examples_for "a simp_apache class" do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('simp_apache') }
  it { is_expected.to create_class('simp_apache::install') }
  it { is_expected.to create_class('simp_apache::conf') }
#  it { is_expected.to contain_file(data_dir) }
  it { is_expected.to contain_file('/etc/httpd/conf/magic') }
  it { is_expected.to contain_file('/etc/httpd/conf.d/welcome.conf').with_ensure('absent') }
  it { is_expected.to contain_file('/etc/mime.types') }
  it { is_expected.to contain_file('/etc/httpd/logs').with_ensure('symlink') }
  it { is_expected.to contain_file('/etc/httpd/modules').with_ensure('symlink') }
  it { is_expected.to contain_file('/etc/httpd/run').with_ensure('symlink') }
  it { is_expected.to contain_file('/var/log/httpd').with_ensure('directory') }
  it { is_expected.to contain_file('httpd_modules').with_ensure('directory') }
  it { is_expected.to contain_group('apache').with_ensure('present') }
  it { is_expected.to contain_service('httpd') }
  it { is_expected.to contain_user('apache') }
end

describe 'simp_apache' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts[:environment] = 'production'
          facts
        end

        context 'with default parameters' do
          it_should_behave_like "a simp_apache class"
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.to create_rsync('site').with({
              :source => "apache_#{environment}_#{facts[:os][:name]}/www"
            })
          }

          it { is_expected.to create_selboolean('httpd_can_network_connect') }
        end

        context 'no_rsync_web_root' do
          let(:params){{ :rsync_web_root => false }}
          it_should_behave_like "a simp_apache class"
          it { is_expected.to create_class('simp_apache::ssl') }
          it { is_expected.not_to create_rsync('site') }
          it { is_expected.to create_selboolean('httpd_can_network_connect') }
        end

        context 'no_ssl' do
          let(:params){{ :ssl => false }}
          it_should_behave_like "a simp_apache class"
          it { is_expected.not_to create_class('simp_apache::ssl') }
          it { is_expected.to create_rsync('site') }
          it { is_expected.to create_selboolean('httpd_can_network_connect') }
        end
      end
    end
  end
end
