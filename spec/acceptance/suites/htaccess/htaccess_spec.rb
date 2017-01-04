require 'spec_helper_acceptance'

test_name "htaccess type/provider"

['6', '7'].each do |os_major_version|
  describe "htaccess type/provider for CentOS #{os_major_version}" do
    let(:host) {only_host_with_role( hosts, "server#{os_major_version}" ) }

    let(:manifest1) { <<EOM
htaccess { 'user1': name => '/root/htaccess.txt:user1', password=>"user1's password" }
htaccess { 'user2': name => '/root/htaccess.txt:user2', password=>"{SHA}yLo2mwINaPQsTgevY0gyfH9mxk4=" }
EOM
    }

    let(:manifest2) { <<EOM
file { '/root/htaccess.txt': ensure => present }
htaccess { 'user1': name => '/root/htaccess.txt:user1', password=>"user1's password" }
htaccess { 'user2': name => '/root/htaccess.txt:user2', password=>"{SHA}yLo2mwINaPQsTgevY0gyfH9mxk4=" }
EOM
    }

    let(:manifest3) { <<EOM
file { '/root/htaccess.txt': ensure => present }
htaccess { 'user1': name => '/root/htaccess.txt:user1', password=>"user1's password", ensure=>absent }
htaccess { 'user2': name => '/root/htaccess.txt:user2', password=>"{SHA}yLo2mwINaPQsTgevY0gyfH9mxk4=", ensure=>absent }
htaccess { 'user3': name => '/root/htaccess.txt:user3', password=>"user3's password" }
EOM
}

    it 'should require file resource' do
      apply_manifest_on(host, manifest1, :expect_failures => true) do
        expect(stderr).to match(/You must declare a 'file' object to manage \/root\/htaccess.txt!/m)
      end
    end

    it 'should work with no errors' do
      apply_manifest_on(host, manifest2, :catch_failures => true)

      on host, 'cat /root/htaccess.txt', :acceptable_exit_codes => 0 do
        lines = stdout.split("\n")
        expect(lines.size).to eq(3)
        expect(lines.first).to eq('# This file managed by Puppet. Please do not edit by hand!')
        # The order of entries is non-deterministic, so test with regex:
        expect(stdout).to match(/^user1:{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=$/)
        expect(stdout).to match(/^user2:{SHA}yLo2mwINaPQsTgevY0gyfH9mxk4=$/)
      end

    end

    it 'should be idempotent' do
      apply_manifest_on(host, manifest2, :catch_changes => true)
    end

    it 'should be be ensurable' do
      apply_manifest_on(host, manifest3, :catch_failures => true)

      expected = <<EOM
# This file managed by Puppet. Please do not edit by hand!
user3:{SHA}UJWYsWH31uLIUPa4iazyItrNbys=
EOM
      on host, 'cat /root/htaccess.txt', :acceptable_exit_codes => 0 do
         expect(stdout).to eq(expected)
      end
    end

  end
end
