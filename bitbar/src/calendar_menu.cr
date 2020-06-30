require "json"
require "http/client"

require "humanize_time"

require "./google/docs"

class EventsPayload
  JSON.mapping(
    events: {type: Array(Event), key: "items"},
  )
end

class EventTime
  JSON.mapping(
    date_time: {type: String?, key: "dateTime"},
    date: String?
  )
end

class EntryPoint
  JSON.mapping(
    entry_point_type: {type: String, key: "entryPointType"},
    uri: String,
  )
end

class Event
  JSON.mapping(
    summary: String,
    start: {type: EventTime},
    location: String?,
    description: String?,
    conference_data: {type: ConferenceData?, key: "conferenceData"},
  )
end

class ConferenceData
  JSON.mapping(
    entry_points: {type: Array(EntryPoint)?, key: "entryPoints"},
  )
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
  return unless text

  match = text.match %r{https://zoom\.us/j/\d+}
  match[0] if match
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

def direct_meeting_url(url)
  return "" unless url

  if url =~ /^zoom.us/
    url.insert(0, "https://")
  end

  match = url.match %r{https://zoom\.us/j/(\d+)}
  return "zoommtg://zoom.us/join?confno=#{match[1]}" if match

  match = url.match %r{https://zoom\.us/my/\w+}
  if match
    response = HTTP::Client.get(match[0])
    url = response.headers["Location"]
    direct_meeting_url(url)
  else
    ""
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
  link = event.location || extract_entry_point(event.conference_data) || extract_zoom_link(event.description)
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
  print event.summary
  puts event.link ? "|href=" + direct_meeting_url(event.link) : ""
  puts event.human_start_time + "|size=12"
  if doc = event.doc
    puts doc.title + "|size=12 href=" + doc.url.to_s
  end
  if event.all_day
    puts "---"
  end
end
