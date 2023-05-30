import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_document.schema'

class AIDocument extends CocoModel { }

AIDocument.className = 'AIDocument'
AIDocument.schema = schema
AIDocument.urlRoot = '/db/ai_document'
AIDocument.prototype.urlRoot = '/db/ai_document'
AIDocument.prototype.defaults = {}

export default AIDocument;
