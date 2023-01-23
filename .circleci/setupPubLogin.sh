cat <<EOF > ~/.pub-cache/credentials.json
{
  "accessToken":"$PUB_DEV_PUBLISH_ACCESS_TOKEN",
  "refreshToken":"$PUB_DEV_PUBLISH_REFRESH_TOKEN",
  "tokenEndpoint":"$PUB_DEV_PUBLISH_TOKEN_ENDPOINT",
  "scopes":["https://www.googleapis.com/auth/userinfo.email","openid"],
  "expiration":$PUB_DEV_PUBLISH_EXPIRATION
}