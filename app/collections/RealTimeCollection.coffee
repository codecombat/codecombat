module.exports = class RealTimeCollection extends Backbone.Firebase.Collection
  constructor: (savePath) ->
    # TODO: Don't hard code this here
    # TODO: Use prod path in prod
    @firebase = 'https://codecombat.firebaseio.com/test/db/' + savePath
    super()
