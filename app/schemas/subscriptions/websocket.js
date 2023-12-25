const c = require('schemas/schemas')

module.exports = {
  'websocket:update-infos': c.object({}),

  'websocket:user-online': c.object({ title: 'Player online states' },
    {
      user: { type: 'object' }
    }
  ),
  'websocket:asking-help': c.object({ title: 'Asking help', description: 'Turn playLevelView to YJS and send message to teacher' },
    {
      msg: { type: 'object' }
    })
}
