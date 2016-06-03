# Litmus OAuth Partner integration example app

## Deployment

This is structured for easy deployment to heroku. At the time of writing
deployed to https://litmus-oauth-example.herokuapp.com

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

