require "json"
require "http/client"

class Issue
  JSON.mapping(
    fields: Fields,
    key: String,
  )
end

class Status
  JSON.mapping(
    name: String,
  )
end

class Fields
  JSON.mapping(
    summary: String,
    status: Status,
  )
end

class SearchPayload
  JSON.mapping(
    issues: Array(Issue),
  )
end

issues_json = File.read("data/jira.json")

begin
  payload = SearchPayload.from_json(issues_json)
rescue e
  puts issues_json
  raise e
end

issues_count = payload.issues.size

puts "Jira (#{issues_count})"

puts "---"

issues = payload.issues.map { |issue|
  url = "https://#{ENV.fetch("JIRA_HOST")}/browse/#{issue.key}"
  puts issue.fields.summary + "|href=" + url
  puts issue.fields.status.name + "|size=12"
}.compact

# issues.each do |issue|
#   print event.summary
#   puts event.link ? "|href=" + direct_meeting_url(event.link) : ""
#   puts event.human_start_time + "|size=12"
#   if event.all_day
#     puts "---"
#   end
# end
