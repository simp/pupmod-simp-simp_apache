require 'spec_helper'

describe 'apache' do
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

  context 'base' do
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
