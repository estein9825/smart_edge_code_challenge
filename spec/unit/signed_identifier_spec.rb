#!/usr/bin/ruby -w
require 'openssl'
require 'base64'
require 'json'
require 'serverspec'
require 'docker'

describe "Smart Edge Challenge Test Suite" do

  describe 'verify necessary files exist in current location' do
    %w( ./private_key.pem ./public_key.pem Dockerfile ).each do |key|
      describe file(key) do
        it { should exist }
        it { should be_file }
      end
    end
  end

  email = ENV['CHALLANGE_EMAIL']

  # email should be supplied and in the proper format
  describe 'verify provided email' do
    it 'should be formatted correctly' do
      expect(email).to_not be_nil
      expect(email).to_not eq ''
      expect(email).to match /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    end
  end

  describe 'verify email encryption with docker run' do

    sig = nil
    stdout = nil

    before(:all) do
      @image = Docker::Image.build_from_dir('.')
      @image.tag('repo' => 'testing', 'force' => true)

      set :os, family: :ruby
      set :backend, :docker
      set :docker_image, @image.id
      set :docker_container_create_options, { 'Entrypoint' => ['ruby', '/home/codechallenge/signed_identifier.rb'] }

    end

    after(:all) do
      @image.remove(:force => true)
    end

    # Docker run should generate the json response (see below)
    it 'should generate a json response' do
      stderr = nil
      Docker::Container.create('Image' => @image.id, 'Cmd' => email ).tap(&:start).attach do |stream, chunk|
        if stream == "stderr"
          stderr = chunk
        else
          stdout = chunk
        end
      end
      #puts stdout
      expect(stdout).to_not be_nil
      expect(stderr).to be_nil
    end

    # response should be in format
    # {
    #    "message":"[EMAIL_ADDRESS]",
    #    "signature":"[RFC 4648 compliant Base64 encoded cryptographic signature of the input]",
    #    "pubkey":"[Base64 encoded string (PEM format) of the public key]"
    # }
    it 'json response should be valid' do
      json = JSON.parse(stdout)
      expect(json).to include 'message'
      expect(json['message']).to_not eq ''
      expect(json['message']).to eq email

      expect(json).to include 'signature'
      sig = json['signature']
      expect(sig).to_not eq ''

      expect(json).to include 'pubkey'
      expect(json['pubkey']).to_not eq ''
    end

    it 'json signature should verify successfully' do
      expect(check_valid(email, sig)).to eq true
    end

    def check_valid(email, sig_enc)
      #puts "email: #{email}, sig: #{sig_enc}"

      sig_unenc = Base64.decode64 sig_enc
      priv_key = OpenSSL::PKey::RSA.new File.read './private_key.pem'
      digest = OpenSSL::Digest('SHA256').new
      priv_key.verify digest, sig_unenc, email

    end
  end
end