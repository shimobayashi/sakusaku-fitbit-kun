require 'pit'
require 'oauth2'

# codeを取得するためのスクリプト

config = Pit.get('sakusaku-fitbit-kun', require: {
  client_id: 'your client id',
  client_secret: 'your client secret',
})

client = OAuth2::Client.new(
  config[:client_id],
  config[:client_secret],
  site: 'https://api.fitbit.com',
  authorize_url: 'https://www.fitbit.com/oauth2/authorize',
  token_url: 'https://api.fitbit.com/oauth2/token'
)

puts 'ここで表示されたURLにアクセスして、認証後にリダイレクトされるURLのクエリパラメータの code を手元に控える。'
puts client.auth_code.authorize_url(scope: 'heartrate')
