# Smart Edge Code Challenge Result
By Ethan Stein

## Overview
The purpose of this project is to demonstrate the coding challenge involved in taking an email address with a public/private keypair and generating a json result int he format:
```
{
   "message":"[EMAIL_ADDRESS]",
   "signature":"[RFC 4648 compliant Base64 encoded cryptographic signature of the input]",
   "pubkey":"[Base64 encoded string (PEM format) of the public key]"
}
```

## Usage
The script is built with ruby and can either be called directly, via:

`signed_identifier.rb <EMAIL_ADDRESS>`

Or by building an image from the Dockerfile accompanying this README

```
docker build . -t codechallenge
docker run codechallenge "super@superfun.com"
```

In either case, the public and private key-pairs must be in the same location as the program/dockerfile, or the program will not run.