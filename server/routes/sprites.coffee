# for sprite page, which uses the age of the files to
# order the sprites and make the more recent ones
# show up at the top

module.exports.setup = (app) ->
  app.get('/server/sprite-info', (req, res) ->
    exec = require('child_process').exec

    child = exec('ls -c1t app/assets/images/sprites/',
      (error, stdout, stderr) ->
        res.write(stdout)
        res.end()
    )
  )
