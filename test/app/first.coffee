# Karma has real issues logging arbitrary objects
# But we log them all the time
# Wrapping console.log so this stops messing up our tests.

ll = console.log

console.log = (splat...) ->
  try
    s = (JSON.stringify(i) for i in splat)
    ll(_.string.join(', ', s...))
  catch TypeError
    console.log('could not log what you tried to log')

console.warn = (splat...) ->
  console.log("WARN", splat...)

console.error = (splat...) ->
  console.log("ERROR", splat...)


# When the page loads the first time, it doesn't actually load if there's no 'me' loaded.
# Get past this by creating a fake 'me'

#User = require 'models/User'
#auth = require 'lib/auth'
#auth.me = new User({anonymous:true})