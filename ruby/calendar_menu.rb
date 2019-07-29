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

events = JSON.parse(events_json)["items"].map { |event|
  link = event["location"] || extract_zoom_link(event["description"])
  if event["start"]["dateTime"]
    start_time = Time.iso8601(event["start"]["dateTime"])
    {
      summary: event["summary"],
      link: link,
      start_time: start_time,
      human_start_time: start_time.strftime("%-I:%M%P").sub(":00", ""),
      all_day: false,
    }
  else
    start_time = Date.iso8601(event["start"]["date"])
    {
      summary: event["summary"],
      start_time: start_time,
      human_start_time: "All dang day",
      all_day: true,
    }
  end
}

next_event = events.select { |event|
  event[:start_time] >= ten_min_ago
}.first

now = Time.now
if next_event
  relative_time = time_ago_in_words(next_event[:start_time]).sub("minute", "min")
  time_msg = if next_event[:start_time] > now
               "in #{relative_time}"
             else
               "#{relative_time} ago"
             end

  puts "#{next_event[:summary].truncate_words(5)} #{time_msg} (#{next_event[:human_start_time]})"
else
  puts "Calendar"
end

puts "---"

events.each do |event|
  print event[:summary]
  puts event[:link] ? "|href=" + direct_meeting_url(event[:link]) : ""
  puts event[:human_start_time] + "|size=12"
  if event[:all_day]
    puts "---"
  end
end
