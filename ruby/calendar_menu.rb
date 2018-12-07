require_relative "lib"

require "json"
require "time"

require "active_support/core_ext/numeric/time"
require "action_view"
require "action_view/helpers"
include ActionView::Helpers::DateHelper

ten_min_ago = Time.now - min(10)
ten_min_since = Time.now + min(10)
ten_hours_since = Time.now + min(10 * 60)

events_json = File.read("data/calendar.json")

upcoming = JSON.parse(events_json)["items"].map { |event|
  link = event["location"] || extract_zoom_link(event["description"])
  start_time = Time.iso8601(event["start"]["dateTime"])
  {
    summary: event["summary"],
    link: link,
    start_time: start_time,
    human_start_time: start_time.strftime("%-I:%M%P").sub(":00", "")
  }
}.select { |event|
  event[:start_time] >= ten_min_ago
}

next_event = upcoming.first

if next_event
  relative_time = time_ago_in_words(next_event[:start_time]).sub("minute", "min")
  puts "#{next_event[:summary]} in #{relative_time} (#{next_event[:human_start_time]})"
else
  puts "Calendar"
end

puts "---"

upcoming.each do |event|
  print event[:summary]
  puts event[:link] ? "|href=" + direct_meeting_url(event[:link]) : ""
  puts event[:human_start_time] + "|size=12"
end
