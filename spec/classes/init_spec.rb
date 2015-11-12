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
    it { should compile.with_all_deps }
    it { should create_class('apache') }
    it { should create_class('apache::conf') }
    it { should create_class('apache::ssl') }
    it { should create_rsync('site') }
    it { should create_selboolean('httpd_can_network_connect') }
  end

  context 'no_rsync_web_root' do
    let(:params){{ :rsync_web_root => false }}

    it { should compile.with_all_deps }
    it { should create_class('apache') }
    it { should create_class('apache::conf') }
    it { should create_class('apache::ssl') }
    it { should_not create_rsync('site') }
    it { should create_selboolean('httpd_can_network_connect') }
  end

  context 'no_ssl' do
    let(:params){{ :ssl => false }}

    it { should compile.with_all_deps }
    it { should create_class('apache') }
    it { should create_class('apache::conf') }
    it { should_not create_class('apache::ssl') }
    it { should create_rsync('site') }
    it { should create_selboolean('httpd_can_network_connect') }
  end
end
