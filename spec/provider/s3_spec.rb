require 'spec_helper'
require 'aws-sdk'
require 'dpl/provider/s3'

describe DPL::Provider::S3 do

  before (:each) do
    AWS.stub!
  end

  subject :provider do
    described_class.new(DummyContext.new, :access_key_id => 'qwertyuiopasdfghjklz', :secret_access_key => 'qwertyuiopasdfghjklzqwertyuiopasdfghjklz', :bucket => 'my-bucket')
  end

  describe "#check_auth" do
    example do
      expect(provider).to receive(:setup_auth)
      expect(provider).to receive(:log).with("Logging in with Access Key: ****************jklz")
      provider.check_auth
    end
  end

  describe "#upload_path" do
    example "Without :upload_dir"do
      filename = "testfile.file"

      expect(provider.upload_path(filename)).to eq("testfile.file")
    end

    example "With :upload_dir" do
      provider.options.update(:upload_dir => 'BUILD3')
      filename = "testfile.file"

      expect(provider.upload_path(filename)).to eq("BUILD3/testfile.file")
    end
  end

  describe "#setup_auth" do
    example "Without :region" do
      expect(AWS).to receive(:config).with(:access_key_id => 'qwertyuiopasdfghjklz', :secret_access_key => 'qwertyuiopasdfghjklzqwertyuiopasdfghjklz', :region => 'us-east-1').once.and_call_original
      provider.setup_auth
    end
    example "With :region" do
      provider.options.update(:region => 'us-west-2')

      expect(AWS).to receive(:config).with(:access_key_id => 'qwertyuiopasdfghjklz', :secret_access_key => 'qwertyuiopasdfghjklzqwertyuiopasdfghjklz', :region => 'us-west-2').once
      provider.setup_auth
    end
  end

describe "#needs_key?" do
    example do
      expect(provider.needs_key?).to eq(false)
    end
  end

  describe "#push_app" do
    example "Without local_dir" do
      expect(Dir).to receive(:chdir).with(Dir.pwd)
      provider.push_app
    end

    example "With local_dir" do
      provider.options.update(:local_dir => 'BUILD')

      expect(Dir).to receive(:chdir).with('BUILD')
      provider.push_app
    end

    example "Sends MIME type" do
      expect(Dir).to receive(:glob).and_yield(__FILE__)
      expect_any_instance_of(AWS::S3::ObjectCollection).to receive(:create).with(anything(), anything(), hash_including(:content_type => 'application/x-ruby'))
      provider.push_app
    end
  end

  describe "#api" do
    example "Without Endpoint" do
      expect(AWS::S3).to receive(:new).with(:endpoint => 's3.amazonaws.com')
      provider.api
    end
    example "With Endpoint" do
      provider.options.update(:endpoint => 's3test.com.s3-website-us-west-2.amazonaws.com')
      expect(AWS::S3).to receive(:new).with(:endpoint => 's3test.com.s3-website-us-west-2.amazonaws.com')
      provider.api
    end
  end
end
