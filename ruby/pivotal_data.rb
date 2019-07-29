require_relative "lib"

require "logger"
require "http"
require "active_support/core_ext/file/atomic"
require "active_support/core_ext/time/calculations"

PIVOTAL_ENDPOINT = "https://www.pivotaltracker.com/services/v5"

http = HTTP #.use(logging: {logger: Logger.new(STDOUT)})
client = http.headers("X-TrackerToken" => ENV.fetch("PIVOTAL_TOKEN"))

project_ids = ENV.fetch("PIVOTAL_PROJECTS").split(",")
filter = "owner:#{ENV.fetch("PIVOTAL_USER")} AND -state:accepted AND -state:unscheduled AND -state:unstarted"
stories = client.get(PIVOTAL_ENDPOINT + "/projects/#{project_ids.first}/stories", params: {filter: filter})
File.atomic_write("data/pivotal.json") do |file|
  file.write(stories.body)
end
