require 'spec_helper'
require 'tempfile'

provider_class = Puppet::Type.type(:htaccess).provider(:htaccess)
describe provider_class do
  before :each do
    FileUtils.stubs(:chown).returns(true) # can't chown root:root
    tmp = Tempfile.new('htaccess_tmp')
    @htaccess_file = tmp.path
    tmp.close!
  end

  after :each do
    FileUtils.rm_f(@htaccess_file)
  end

  let(:user1) { 'user1' }
  let :resource do
    Puppet::Type::Htaccess.new(
      {:name => "#{@htaccess_file}:#{user1}", :password => "#{user1}'s password"}
    )
  end

  context "when creating htaccess file" do
    let :provider do
      provider_class.new(resource)
    end

    it 'should not exist' do
      expect { provider.exists? }.to raise_error(/No such file or directory .*#{@htaccess_file}/)
      expect(provider.passwd_retrieve).to be_nil
    end

    it 'should create htaccess file with banner and one user entry' do
      provider.create
      expected = <<EOM
# This file managed by Puppet. Please do not edit by hand!
user1:{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=
EOM
      expect(IO.read(@htaccess_file)).to eq(expected)
      expect(provider.exists?).to eq(true)
      expect(provider.passwd_retrieve).to eq("{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=")
    end
  end

  context "when adding to htaccess file with banner" do
    let :provider do
      provider_class.new(resource)
    end

    it 'should add user entry to end of htaccess file' do
      File.open(@htaccess_file, 'w') do |file|
        file.puts("# This file managed by Puppet. Please do not edit by hand!")
        file.puts("anotheruser:{SHA}deadbeefdeadbeefdeadbeefdead")
      end

      provider.create
      expected = <<EOM
# This file managed by Puppet. Please do not edit by hand!
anotheruser:{SHA}deadbeefdeadbeefdeadbeefdead
user1:{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=
EOM
      expect(IO.read(@htaccess_file)).to eq(expected)
      expect(provider.exists?).to eq(true)
      expect(provider.passwd_retrieve).to eq("{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=")
    end
  end

  context "when adding to htaccess file missing banner" do
    let :provider do
      provider_class.new(resource)
    end

    it 'should add banner and user entry to htaccess file' do
      File.open(@htaccess_file, 'w') do |file|
        file.puts("anotheruser:{SHA}deadbeefdeadbeefdeadbeefdead")
      end

      provider.create
      expected = <<EOM
# This file managed by Puppet. Please do not edit by hand!
anotheruser:{SHA}deadbeefdeadbeefdeadbeefdead
user1:{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=
EOM
      expect(IO.read(@htaccess_file)).to eq(expected)
      expect(provider.exists?).to eq(true)
      expect(provider.passwd_retrieve).to eq("{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=")
    end
  end

  context "when adding to htaccess file using hashed password" do
    let :resource2 do
      Puppet::Type::Htaccess.new(
        {:name => "#{@htaccess_file}:#{user1}", :password => "{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo="}
      )
    end

    let :provider do
      provider_class.new(resource2)
    end

    it 'should add user entry using pre-hashed password to htaccess file' do
      provider.create
      expected = <<EOM
# This file managed by Puppet. Please do not edit by hand!
user1:{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=
EOM
      expect(IO.read(@htaccess_file)).to eq(expected)
      expect(provider.exists?).to eq(true)
      expect(provider.passwd_retrieve).to eq("{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=")
    end
  end
  
  context "when updating htaccess file" do
    let :provider do
      provider_class.new(resource)
    end

    it 'should replace password of user entry in htaccess file' do
      File.open(@htaccess_file, 'w') do |file|
        file.puts("#{user1}:{SHA}deadbeefdeadbeefdeadbeefdead")
      end

      provider.passwd_sync
      expected = <<EOM
# This file managed by Puppet. Please do not edit by hand!
user1:{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=
EOM
      expect(IO.read(@htaccess_file)).to eq(expected)
      expect(provider.exists?).to eq(true)
      expect(provider.passwd_retrieve).to eq("{SHA}CLub7iwpjkqz0enKLoRcbiDtUCo=")
    end
  end

  context "when removing user entry from htaccess file" do
    let :provider do
      provider_class.new(resource)
    end

    it 'should remove user entry in htaccess file' do
      File.open(@htaccess_file, 'w') do |file|
        file.puts("user0:{SHA}deadbeefdeadbeefdeadbeefdead")
        file.puts("#{user1}:{SHA}deadbeefdeadbeefdeadbeefdead")
        file.puts("user2:{SHA}deadbeefdeadbeefdeadbeefdead")
      end

      provider.destroy
      expected = <<EOM
# This file managed by Puppet. Please do not edit by hand!
user0:{SHA}deadbeefdeadbeefdeadbeefdead
user2:{SHA}deadbeefdeadbeefdeadbeefdead
EOM
      expect(IO.read(@htaccess_file)).to eq(expected)
      expect(provider.exists?).to eq(false)
      expect(provider.passwd_retrieve).to be_nil
    end
  end
end
