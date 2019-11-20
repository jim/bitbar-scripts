require "http/client"
require "json"

require "atomic_write"

TOKEN_ENDPOINT  = "https://www.googleapis.com/oauth2/v4/token"
EVENTS_ENDPOINT = "https://www.googleapis.com/calendar/v3/calendars/primary/events"

params = {
  client_id:     ENV.fetch("GCAL_CLIENT_ID"),
  client_secret: ENV.fetch("GCAL_CLIENT_SECRET"),
  grant_type:    "refresh_token",
  refresh_token: ENV.fetch("GCAL_REFRESH_TOKEN"),
}
token_response = HTTP::Client.post(TOKEN_ENDPOINT + "?" + HTTP::Params.encode(params))

data = Hash(String, String | Int32).from_json(token_response.body)
token = data["access_token"]

thirty_min_ago = Time.utc - 30.minutes
eod = Time.utc.at_end_of_day

event_params = {
  orderBy:      "startTime",
  singleEvents: true.to_s,
  timeZone:     "America/Chicago",
  timeMin:      thirty_min_ago.to_rfc3339,
  timeMax:      eod.to_rfc3339,
}

headers = HTTP::Headers.new
headers.add "Authorization", "Bearer #{token}"
events = HTTP::Client.get(EVENTS_ENDPOINT + "?" + HTTP::Params.encode(event_params), headers)

if events.status.code == 200
  File.atomic_write("data/calendar.json") do |file|
    file << events.body
  end
else
  raise "error contacting the calendar server"
end
