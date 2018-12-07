def min(n)
  60 * n
end

def extract_zoom_link(text)
  return unless text

  match = text.match %r{https://zoom\.us/j/\d+}
  match[0] if match
end

def direct_meeting_url(url)
match = url.match %r{https://zoom\.us/j/(\d+)}
return "zoommtg://zoom.us/join?confno=#{match[1]}" if match

match = url.match %r{https://zoom\.us/my/\w+}
  if match
      url = HTTP.get(match[0]).headers["Location"]
      direct_meeting_url(url)
  end
end