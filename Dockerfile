FROM ruby:2.3.0
LABEL maintainer="Ethan Stein (ethan.stein@yahoo.com)"
LABEL description="Creates a docker image for signed_identifier ruby script, which will take in an email address and generated a json result"
LABEL version="1.0"

WORKDIR '/home/codechallenge'

COPY *.pem "/home/codechallenge/"
COPY *.rb "/home/codechallenge/"

ENTRYPOINT ["ruby","/home/codechallenge/signed_identifier.rb"]

