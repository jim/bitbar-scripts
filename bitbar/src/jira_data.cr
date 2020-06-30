require "http/client"

require "atomic_write"

ISSUES_ENDPOINT = "/rest/api/2/search?jql=assignee=currentuser()"

client = HTTP::Client.new(ENV.fetch("JIRA_HOST"), tls: true)
client.basic_auth(ENV.fetch("JIRA_USER"), ENV.fetch("JIRA_TOKEN"))
issues = client.get(ISSUES_ENDPOINT)

if issues.status.code == 200
  File.atomic_write("data/jira.json") do |file|
    file << issues.body
  end
else
  raise "error contacting jira"
end
