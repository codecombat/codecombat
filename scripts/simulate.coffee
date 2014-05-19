spawn = require("child_process").spawn

[sessionOne, sessionTwo] = [process.argv[2],process.argv[3]]

unless sessionOne and sessionTwo and sessionOne.length is 24 and sessionTwo.length is 24
  console.log "Not enough games to continue!"
  process.exit(1)
command = "coffee ../headless_client.coffee one-game"
run = (cb) ->
  command = spawn("coffee",["headless_client.coffee","one-game"],{cwd:"/Users/schmatz/codecombat/"})
  result = ""
  command.stdout.on 'data', (data) ->
    result += data.toString()
  command.stdout.on 'close', ->
    return cb(result)
run (result) ->
  process.stdout.write result
  process.exit(0)
    
 