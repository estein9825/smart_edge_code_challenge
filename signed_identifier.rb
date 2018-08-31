#!/usr/bin/ruby -w
#
# Application takes in an email address and returns a json message in the format:
# {
#   "message":"[EMAIL_ADDRESS]",
#   "signature":"[RFC 4648 compliant Base64 encoded cryptographic signature of the input]",
#   "pubkey":"[Base64 encoded string (PEM format) of the public key]"
# }
# using a provided public and private keypair
# For example:
#
# ./signed_identifier.rb "your@email.com"
#
# may yield:
# {
#   "message":"your@email.com",
#   "signature":"MGUCMGrxqpS689zQEi5yoBElG41u6U7eKX7ZzaXmXr0C5HgNXlJbiiVQYUS0ZOBxsLU4UgIxAL9AAgkRBUQ7/3EKQag4MjRflAxbfpbGmxb6ar9d4bGZ8FDQkUe6cnCIRleaxFnu2A==",
#   "pubkey":"-----BEGIN PUBLIC KEY-----\nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEDUlT2XxqQAR3PBjeL2D8pQJdghFyBXWI\n/7RvD8Tsdv1YVFwqkJNEC3lNS4Gp7a19JfcrI/8fabLI+yPZBPZjtvuwRoauvGC6\nwdBrL2nzrZxZL4ZsUVNbWnG4SmqQ1f2k\n-----END PUBLIC KEY-----\n"
# }
require 'openssl'
require 'base64'
require 'json'

=begin
Creates a signed identifier JSON message based on
an inputted email address and private and public keys
=end
def signed_identifier(email)

  # read in public and private keys
  priv_key = OpenSSL::PKey::RSA.new File.read './private_key.pem'
  pub_key = OpenSSL::PKey::RSA.new File.read './public_key.pem'

  # Create an SHA256 digest
  digest = OpenSSL::Digest('SHA256').new

  # Create an SHA256 signature of the email using the private key
  signature = priv_key.sign digest, email

  # verify key
  if priv_key.verify digest, signature, email
    # puts 'Valid signature'
  else
    raise "Invalid signature for #{email}!!!!"
  end

  # encode the signature
  sig_enc = Base64.strict_encode64 signature

  # build json and return it
  result = {
      'message' => email,
      'signature' => sig_enc,
      'pubkey' => pub_key.to_s
  }
  return JSON[result]

end

# main method
if ARGV.length < 1 then
  raise "Missing email address input parameter:\n> signed_identifier.rb <email_address>\ne.g. signed_identifer.rb joe_cool@joecool.com"
end

email = ARGV[0]

puts signed_identifier(email)