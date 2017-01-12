require 'spec_helper_acceptance'

test_name 'apache class'

describe 'apache class' do
  hosts.each do |host|

    context 'basic parameters' do
      let(:manifest) { "include 'simp_apache'" }
      let(:host_fqdn) { fact_on(host, 'fqdn') }
      let(:hieradata) {{
        'simp_apache::rsync_web_root' => false,
        'simp_options::pki'           => true,
        'simp_options::pki::source'   => '/etc/pki/simp-testing/pki/'
      }}

      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should respond to http' do
        result = on(host,'curl localhost')
        expect(result.output).to match(/You don't have permission to access \//)
      end
    end
  end
end
