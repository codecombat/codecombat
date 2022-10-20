const c = require('schemas/schemas')

module.exports = {
  'websocket:update-infos': c.object({}),

  'websocket:user-online': c.object({title: 'Player online states'},
                                    {
                                      user: {type: 'object'},
                                    }
                                   )
}
