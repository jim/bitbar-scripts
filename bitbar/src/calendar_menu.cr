require "json"
require "http/client"

class EventTime
  JSON.mapping(
    date_time: {type: String?, key: "dateTime"},
    date: String?
  )
end

class EntryPoint
  JSON.mapping(
    entry_point_type: String,
    uri: String,
  )
end

class Event
  JSON.mapping(
    summary: String,
    start: {type: EventTime},
    location: String,
    description: String,
    entry_points: Array(EntryPoint),
  )
end

record CalendarEvent,
  summary : String,
  link : String?,
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

def extract_entry_point(entry_points)
  entry_points.each do |entry_point|
    return entry_point.uri if entry_point.entry_point_type == "video"
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

events_json = File.read("data/calendar.json")

begin
  raw_events = Array(Event).from_json(events_json)
rescue e
  puts events_json
  raise e
end

events = raw_events.map { |event|
  link = event.location || extract_entry_point(event.entry_points) || extract_zoom_link(event.description)
  date = event.start.date
  date_time = event.start.date_time
  if date
    start_time = Time::Format::ISO_8601_DATE_TIME.parse(date)
    CalendarEvent.new(
      summary: event.summary,
      link: nil,
      start_time: start_time,
      human_start_time: "All dang day",
      all_day: true,
    )
  elsif date_time
    start_time = Time::Format::ISO_8601_DATE_TIME.parse(date_time)
    CalendarEvent.new(
      summary: event.summary,
      link: link,
      start_time: start_time,
      human_start_time: start_time.to_s("%-I:%M%P").sub(":00", ""),
      all_day: false,
    )
  end
}.compact

next_event = events.select { |event|
  event.start_time >= ten_min_ago
}.first

now = Time.local
if next_event
  relative_time = next_event.start_time # time_ago_in_words(next_event[:start_time]).sub("minute", "min")
  time_msg = if next_event.start_time > now
               "in #{relative_time}"
             else
               "#{relative_time} ago"
             end

  # puts "#{next_event[:summary].truncate_words(5)} #{time_msg} (#{next_event[:human_start_time]})"
  puts "#{next_event.summary} #{time_msg} (#{next_event.human_start_time})"
else
  puts "Calendar"
end

puts "---"

events.each do |event|
  print event.summary
  puts event.link ? "|href=" + direct_meeting_url(event.link) : ""
  puts event.human_start_time + "|size=12"
  if event.all_day
    puts "---"
  end
end
