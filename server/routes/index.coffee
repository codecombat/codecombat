module.exports.setup = (app) ->
  app.get('/db/products', require('./db/products').get)