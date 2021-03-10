require "json"
require "http/client"

require "humanize_time"

require "./google/docs"
require "./zoom"

class EventsPayload
  include JSON::Serializable

  @[JSON::Field(key: "items")]
  property events : Array(Event)
end

class EventTime
  include JSON::Serializable

  property date : String?

  @[JSON::Field(key: "dateTime")]
  property date_time : String?
end

class EntryPoint
  include JSON::Serializable

  property uri : String

  @[JSON::Field(key: "entryPointType")]
  property entry_point_type : String
end

class Event
  include JSON::Serializable

  property summary : String
  property start : EventTime
  property location : String?
  property description : String?

  @[JSON::Field(key: "conferenceData")]
  property conference_data : ConferenceData?
end

class ConferenceData
  include JSON::Serializable

  @[JSON::Field(key: "entryPoints")]
  property entry_points : Array(EntryPoint)?
end

record CalendarEvent,
  summary : String,
  link : String?,
  doc : Google::Document? | Google::LoadingDocument?,
  start_time : Time,
  human_start_time : String,
  all_day : Bool

ten_min_ago = Time.utc - 10.minutes
ten_min_since = Time.utc + 10.minutes
ten_hours_since = Time.utc + 6.hours

def extract_zoom_link(text)
  Zoom.extract_url(text)
end

def extract_entry_point(conference_data)
  return if conference_data.nil?

  entry_points = conference_data.entry_points
  return if entry_points.nil?

  entry_points.each do |entry_point|
    return entry_point.uri if entry_point.entry_point_type == "video"
  end
end

def extract_doc(description)
  return unless description

  match = description.match %r{https://docs.google.com/document/d/([^\s/]+)}
  if match
    Google::Docs.new.cached_document(match[1]) if match
  end
end

def format_time(time)
  time.to_s("%I:%M%p").sub(":00", "").strip("0")
end

api = Google::API.new

events_json = api.cache_read("data/calendar")
if !events_json
  raise "no calendar events found"
  exit
end

begin
  payload = EventsPayload.from_json(events_json)
rescue e
  puts events_json
  raise e
end

events = payload.events.map { |event|
  link = extract_zoom_link(event.location) || extract_entry_point(event.conference_data) || extract_zoom_link(event.description)
  date = event.start.date
  date_time = event.start.date_time
  doc = extract_doc(event.description)
  if date
    start_time = Time::Format::ISO_8601_DATE.parse(date)
    CalendarEvent.new(
      summary: event.summary,
      link: nil,
      doc: doc,
      start_time: start_time,
      human_start_time: "All dang day",
      all_day: true,
    )
  elsif date_time
    start_time = Time::Format::ISO_8601_DATE_TIME.parse(date_time)
    CalendarEvent.new(
      summary: event.summary,
      link: link,
      doc: doc,
      start_time: start_time,
      human_start_time: format_time(start_time),
      all_day: false,
    )
  end
}.compact

next_events = events.select { |event|
  event.start_time >= ten_min_ago
}

now = Time.local
if next_events.any?
  next_event = next_events.first
  relative_time = HumanizeTime.distance_of_time_in_words(now, next_event.start_time)
  time_msg = if next_event.start_time > now
               "in #{relative_time}"
             else
               "#{relative_time} ago"
             end

  puts "#{next_event.summary} #{time_msg} (#{next_event.human_start_time})"
else
  puts "Calendar"
end

puts "---"

events.each do |event|
  print event.summary.strip
  puts event.link ? "|href=" + Zoom.direct_meeting_url(event.link) : ""
  puts event.human_start_time + "|size=12"
  if doc = event.doc
    puts doc.title + "|size=12 href=" + doc.url.to_s
  end
  if event.all_day
    puts "---"
  end
end
