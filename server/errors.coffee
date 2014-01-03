
module.exports.notFound = (req, res, message) ->
  res.status(404)
  message = "Route #{req.path} not found." unless message
  res.write(message)
  res.end()

module.exports.badMethod = (res) ->
  res.status(405)
  res.send('Method not allowed.')
  res.end()

module.exports.badInput = (res) ->
  res.status(422)
  res.send('Bad post input.')
  res.end()

module.exports.conflict = (res) ->
  res.status(409)
  res.send('File exists.')
  res.end()

module.exports.serverError = (res) ->
  res.status(500)
  res.send('Server error.')
  res.end()

module.exports.unauthorized = (res) ->
  res.status(403)
  res.send('Unauthorized.')
  res.end()