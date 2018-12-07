require_relative "lib"

require "logger"
require "http"
require "active_support/core_ext/file/atomic"

TOKEN_ENDPOINT = "https://www.googleapis.com/oauth2/v4/token"
EVENTS_ENDPOINT = "https://www.googleapis.com/calendar/v3/calendars/primary/events"

http = HTTP#.use(logging: {logger: Logger.new(STDOUT)})

token_response = http.post(TOKEN_ENDPOINT, params: {
  client_id: ENV.fetch("GCAL_CLIENT_ID"),
  client_secret: ENV.fetch("GCAL_CLIENT_SECRET"),
  grant_type: "refresh_token",
  refresh_token: ENV.fetch("GCAL_REFRESH_TOKEN"),
})

token = token_response.parse["access_token"]

ten_min_ago = Time.now - min(10)
ten_min_since = Time.now + min(10)
ten_hours_since = Time.now + min(10 * 60)

events = http.auth("Bearer #{token}").get(EVENTS_ENDPOINT, params: {
  orderBy: "startTime",
  singleEvents: true,
  timeZone: "America/Chicago",
  timeMin: ten_min_ago.to_datetime.rfc3339,
  timeMax: ten_hours_since.to_datetime.rfc3339,
})

File.atomic_write('data/calendar.json') do |file|
  file.write(events.body)
end