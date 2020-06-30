require_relative "lib"

require "json"
require "time"

require "active_support/core_ext/numeric/time"
require "action_view"
require "action_view/helpers"
include ActionView::Helpers::DateHelper

stories_json = File.read("data/pivotal.json")
stories = JSON.parse(stories_json)

if stories.is_a? Hash # should be an array it it was working
  puts "Pivotal is down ☹️"
  puts "---"
  puts stories["error"]
  exit
end

print "Pivotal"
puts stories.size > 0 ? " (#{stories.size})" : ""

puts "---"


stories.each do |story|
  print story["name"]
  puts "|href=" + story["url"]
  puts story["labels"].map { |l| l["name"] }.join(", ") + "|size=12"
  puts "---"
end
