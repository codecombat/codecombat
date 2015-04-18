spawn = require('child_process').spawn

[sessionOne, sessionTwo] = [process.argv[2], process.argv[3]]
homeDirectory = process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE
unless sessionOne and sessionTwo and sessionOne.length is 24 and sessionTwo.length is 24
  console.log 'Not enough games to continue!'
  process.exit(1)
run = (cb) ->
  command = spawn('coffee', ['headless_client.coffee', 'one-game', sessionOne, sessionTwo], {cwd: homeDirectory + '/codecombat/'})
  result = ''
  command.stdout.on 'data', (data) ->
    result += data.toString()
  command.stdout.on 'close', ->
    return cb(result)
run (result) ->
  lines = result.split("\n")
  for line in lines
    if line.slice(0, 10) is 'GAMERESULT'
      process.stdout.write line.slice(11)
      process.exit(0)
  process.exit(0)
