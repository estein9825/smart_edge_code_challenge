# Smart Edge Code Challenge Result
By Ethan Stein

## Overview
The purpose of this project is to demonstrate the coding challenge involved in taking an email address with a public/private keypair and generating a json string result in the format:
```
{
   "message":"[EMAIL_ADDRESS]",
   "signature":"[RFC 4648 compliant Base64 encoded cryptographic signature of the input]",
   "pubkey":"[Base64 encoded string (PEM format) of the public key]"
}
```
The program has been built using Ruby and leverages the OpenSSL, Base64, and Json libraries.

## Usage
The program can either called directly, via:

`./signed_identifier.rb <EMAIL_ADDRESS>` 

where `<EMAIL_ADDRESS>` is a simple string, or by building an image from the Dockerfile accompanying this README:
```
docker build . -t codechallenge
docker run codechallenge "super@superfun.com"
```

In either case, the public and private key-pairs must be in the same location as the program/dockerfile, or the program will not run.

## Testing

A serverspec test suite has been created to verify the following:
1. The private and public keys are available in the current directory (as well as the Dockerfile for good measure)
2. The `CHALLANGE_EMAIL` environment variable is of a valid format and not null/empty
2. Docker creates a valid json response using the email, defined by the format above
3. The json `message` field is the same as the provided email
4. The json `signature` field successfully verifies against the email address and private key. 

To run the test suite execute the following commands:

```
bundle install
export CHALLANGE_EMAIL="something@test.com"
rspec spec/unit/signed_identifier_spec.rb
```

The result should be similar to

```
Using bundler 1.16.4
...
Using serverspec 2.41.3
Bundle complete! 3 Gemfile dependencies, 18 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

Smart Edge Challenge Test Suite
  verify necessary files exist in current location
    File "./private_key.pem"
      should exist
      should be file
    File "./public_key.pem"
      should exist
      should be file
    File "Dockerfile"
      should exist
      should be file
  verify provided email
    should be formatted correctly
  verify email encryption with docker run
    should generate a json response
    json response should be valid
    json signature should verify successfully

Finished in 5.06 seconds (files took 0.8341 seconds to load)
10 examples, 0 failures
```

Simply update the `CHALLANGE_EMAIL` environment variable and run the rspec command again to test a different email address.

**Note**: the test suite will take care of building the Docker image, creating the container, and cleaning up the image and container after. No manual cleanup should be required.

## Use Cases
To leverage this functionality with continuous integration, you can incorporate it into a chef cookbook with the [execute](https://docs.chef.io/resource_execute.html) resource:
```
remote_file '/tmp/kitchen/private_key.pem' do
  source 'file:///home/codechallenge/private_key.pem'
end
remote_file '/tmp/kitchen/public_key.pem' do
  source 'file:///home/codechallenge/public_key.pem'
end
remote_file '/tmp/kitchen/signed_identifier.rb' do
  source 'file:///home/codechallenge/signed_identifier.rb'
end
node.default['test']['email']='me@me.co'
execute 'verify_email' do
  command "/tmp/kitchen/signed_identifier.rb \"#{node['test']['email']}\""
end
```
Alternatively, you can rebuild the ruby script as part of a RESTful API web application that will receive an email address as a GET parameter. Then deploy it as a docker package in a cloud instance, and expose a service that will allow people to make the GET call.

Or, at they very least, you can hook a github repository like this one to a docker repository and set up an auto-build function, so whenever new changes are pushed to the github repository, then the docker image will be rebuilt automatically.