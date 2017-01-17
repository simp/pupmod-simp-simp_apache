require 'spec_helper'

describe 'simp_apache::site' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          let(:title) {'test'}
          let(:params) {{ :content => 'test' }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('simp_apache') }
          it { is_expected.to contain_file("/etc/httpd/conf.d/#{title}.conf").with_content('test') }
        end
      end
    end
  end
end
