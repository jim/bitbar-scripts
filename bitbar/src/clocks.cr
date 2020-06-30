def format(time)
  time.to_s("%I:%M%p").strip("0")
end

here = Time.local
there = Time.local(location: Time::Location.load("America/Los_Angeles"))
puts format(here) + " 🕰 " + format(there)
