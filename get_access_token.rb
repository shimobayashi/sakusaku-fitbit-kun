require 'pit'
require 'oauth2'
require 'base64'

# access_tokenをPitに保存するためのスクリプト

config = Pit.get('sakusaku-fitbit-kun', require: {
  client_id: 'your client id',
  client_secret: 'your client secret',
  code: 'your code',
})

client = OAuth2::Client.new(
  config[:client_id],
  config[:client_secret],
  site: 'https://api.fitbit.com',
  authorize_url: 'https://www.fitbit.com/oauth2/authorize',
  token_url: 'https://api.fitbit.com/oauth2/token'
)

bearer_token = "#{config[:client_id]}:#{config[:client_secret]}"
encoded_bearer_token = Base64.strict_encode64(bearer_token)

access_token = client.auth_code.get_token(
  config[:code],
  client_id: config[:client_id],
  headers: {
    Authorization: "Basic #{encoded_bearer_token}"
  }
)

config[:access_token] = access_token.to_hash
Pit.set('sakusaku-fitbit-kun', data: config)
puts 'done.'
