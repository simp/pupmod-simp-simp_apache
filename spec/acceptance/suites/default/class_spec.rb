require 'spec_helper_acceptance'

test_name 'apache class'

describe 'apache class' do
  hosts.each do |host|

    context 'basic parameters' do
      let(:manifest) {
        "class { 'simp_apache': }"
      }
      let(:host_fqdn) { fact_on(host, 'fqdn') }
      let(:hieradata) {{
        'simp_apache::rsync_web_root'      => false,
        'simp_apache::ssl::app_pki_ca_dir' => '/etc/pki/simp-testing/pki/cacerts',
        'simp_apache::ssl::app_pki_cert'   => "/etc/pki/simp-testing/pki/public/#{host_fqdn}.pub",
        'simp_apache::ssl::app_pki_key'    => "/etc/pki/simp-testing/pki/private/#{host_fqdn}.pem"
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
