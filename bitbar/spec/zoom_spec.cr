require "./spec_helper"
require "./../src/zoom"

describe Zoom do
  urls = [
    "https://zoom.us/j/123456789",
    "https://sub-domain.zoom.us/j/123456789",
    "https://us02web.zoom.us/j/12345?pwd=acbdefg",
    "https://us02web.zoom.us/j/12345?pwd=acbdefg&arg=value",
    "https://truss-works.zoom.us/j/93320876431",
    "https://truss-works.zoom.us/j/93320876431?pwd=aBcD123",
  ]

  urls.each do |url|
    it "finds a URL that looks like #{url}" do
      Zoom.extract_url(url).should eq(url)
    end
  end

  urls.each do |url|
    it "finds a URL that looks like #{url} inside text" do
      Zoom.extract_url("here is a URL: #{url} did you find it?").should eq(url)
    end
  end

  it "determines direct meeting URLs" do
    Zoom.direct_meeting_url("https://truss-works.zoom.us/j/93320876431").should eq("zoommtg://zoom.us/join?confno=93320876431")
    Zoom.direct_meeting_url("https://zoom.us/j/6714206669").should eq("zoommtg://zoom.us/join?confno=6714206669")
  end
end
