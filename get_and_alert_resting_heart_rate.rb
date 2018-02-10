require 'pit'
require 'oauth2'
require 'base64'
require 'rest-client'

# 安静時心拍数をFitbitから取得してSlackへ通知するスクリプト
#
# デイリーでの実行を想定しており、Fitbitから取得できるaccess_tokenの有効期限は最大で8時間であるため、実行毎にaccess_tokenをrefreshする。
# refresh_tokenには期限が無いためこのような動作が可能となる。
# 実行前に各種セットアップスクリプトを実行してPitへ必要な情報を保存しておくこと。

config = Pit.get('sakusaku-fitbit-kun', require: {
  webhook_url: 'your slack incoming webhook url',
})

client = OAuth2::Client.new(
  config[:client_id],
  config[:client_secret],
  site: 'https://api.fitbit.com',
  authorize_url: 'https://www.fitbit.com/oauth2/authorize',
  token_url: 'https://api.fitbit.com/oauth2/token'
)

# Pitから前回のaccess_tokenを取得し、refreshしたものをPitに保存する
access_token = OAuth2::AccessToken.from_hash(client, config[:access_token])

bearer_token = "#{config[:client_id]}:#{config[:client_secret]}"
encoded_bearer_token = Base64.strict_encode64(bearer_token)

access_token = access_token.refresh!(
  headers: {
    Authorization: "Basic #{encoded_bearer_token}"
  }
)

config[:access_token] = access_token.to_hash
Pit.set('sakusaku-fitbit-kun', data: config)

# 新しいaccess_tokenを使ってAPIにアクセスする
response = access_token.get('https://api.fitbit.com/1/user/-/activities/heart/date/today/30d.json')
json = JSON.parse(response.body)
stats = json['activities-heart'].map{|item| { datetime: item['dateTime'], resting_heart_rate: item['value']['restingHeartRate'] }}

# 取得結果を計算して通知する
today_stat = stats.pop
recent_stats = stats.pop(14)

recent_rates = recent_stats.select{|item| item[:resting_heart_rate]}.map{|item| item[:resting_heart_rate]}
recent_avg_rate = recent_rates.size ? (recent_rates.reduce(:+).to_f / recent_rates.size).round(1) : nil

today_rate = today_stat[:resting_heart_rate]

if today_rate
  message = ''
  message += "本日の安静時心拍数は#{today_rate}でした。"
  message += "直近2週間の平均安静時心拍数は#{recent_avg_rate || '計算できません'}でした。"
  if recent_avg_rate && today_rate > (recent_avg_rate + 1.0)
    message += '安静時心拍数が高まっています。定時で帰りましょう。'
  end

  RestClient.post(
    config[:webhook_url],
    {
      payload: {
        text: message,
      }.to_json,
    }
  )
end
