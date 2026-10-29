import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_story_world.schema'

class AIStoryWorld extends CocoModel { }

AIStoryWorld.className = 'AIStoryWorld'
AIStoryWorld.schema = schema
AIStoryWorld.urlRoot = '/db/ai_story_world'
AIStoryWorld.prototype.urlRoot = '/db/ai_story_world'
AIStoryWorld.prototype.defaults = {}

module.exports = AIStoryWorld
