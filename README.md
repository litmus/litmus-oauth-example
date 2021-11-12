# Litmus OAuth: Example Partner Integration

A minimal example of integrating with Litmus APIs using Litmus OAuth.

The example uses ruby, sinatra, [omniauth-litmus](https://github.com/litmus/omniauth-litmus) and the [instant-api ruby client](https://github.com/litmus/instant-api-ruby).

## Prerequisites

- ruby 2.7.0
- bundler
- a valid Litmus OAuth `client_id` and `client_secret`

## Setup

```sh
bundle
```

## Deployment

This is structured for easy deployment to heroku. At the time of writing
deployed to https://litmus-oauth-example.herokuapp.com

## Running locally

```sh
source .env && bundle exec thin start --ssl --ssl-disable-verify --port 4567
```

Then use https://litmus-oauth-example.127.0.0.1.nip.io:4567 (OAuth callback URLs
require HTTPS)

Within Litmus the application must have a callback URL specified of:
```
https://litmus-oauth-example.127.0.0.1.nip.io:4567/auth/litmus/callback
```

## ENV vars

Example:
```
# required
export OAUTH2_CLIENT_ID="f9f75cad29d77b581f1a872f09b2143a23739906a6aab5cbcd727cba371b8932"
export OAUTH2_CLIENT_SECRET="b68309ca4e6edca4d673f2827050fcfe85b56bcf97e602699a7905c4cfafd86a"

# optional
export INSTANT_BASE_URI="http://0.0.0.0:3000/v1"
export INSTANT_SKIP_SSL_VERIFICATION=true
export LITMUS_OAUTH_HOST="http://localhost:3000"
```
