require "http"

module Zoom
  def self.extract_url(text)
    return unless text
    match = text.match %r{(https://(.*\.)?zoom\.us/j/\d+(\?\S*)?)}
    match[0] if match
  end

  def self.direct_meeting_url(url)
    return "" unless url

    if url !~ /^http/
      url.insert(0, "https://")
    end

    match = url.match %r{https://(?:.*\.)?zoom\.us/j/(\d+)(?:\?(\S*))?}
    if match
      return "zoommtg://zoom.us/join?confno=#{match[1]}&#{match[2]}" if match[2]?
      return "zoommtg://zoom.us/join?confno=#{match[1]}"
    end

    match = url.match %r{https://zoom\.us/my/\w+}
    if match
      response = HTTP::Client.get(match[0])
      url = response.headers["Location"]
      direct_meeting_url(url)
    else
      ""
    end
  end
end
