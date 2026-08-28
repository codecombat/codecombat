import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/mini_game.schema'

class MiniGame extends CocoModel { }

MiniGame.className = 'MiniGame'
MiniGame.schema = schema
MiniGame.urlRoot = '/db/mini_game'
MiniGame.prototype.urlRoot = '/db/mini_game'

module.exports = MiniGame
