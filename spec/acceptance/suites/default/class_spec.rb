require 'spec_helper_acceptance'

test_name 'apache class'

describe 'apache class' do
  hosts.each do |host|
    context 'basic parameters' do
      let(:manifest) { "include 'simp_apache'" }
      let(:host_fqdn) { fact_on(host, 'fqdn') }
      let(:hieradata) do
        {
          'simp_apache::rsync_web_root' => false,
       'simp_options::pki'           => true,
       'simp_options::pki::source'   => '/etc/pki/simp-testing/pki/',
        }
      end

      it 'works with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        puppet_version = pfact_on(host, 'puppetversion')
        if Gem::Version.new(puppet_version) < Gem::Version.new('6.23.0')
          # Additional run to work around PUP-7559
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'responds to http' do
        result = on(host, 'curl localhost')
        expect(result.output).to match(%r{You don't have permission to access })
      end
    end
  end
end
