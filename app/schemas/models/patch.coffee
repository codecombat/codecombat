c = require './../schemas'

patchables = ['level', 'thang_type', 'level_system', 'level_component', 'article']
  
PatchSchema = c.object({title:'Patch', required:['target', 'delta', 'commitMessage']}, {
  delta: { title: 'Delta', type:['array', 'object'] }
  commitMessage: c.shortString({maxLength: 500, minLength: 1})
  creator: c.objectId(links: [{rel: 'extra', href: "/db/user/{($)}"}])
  created: c.date( { title: 'Created', readOnly: true })
  status: { enum: ['pending', 'accepted', 'rejected', 'withdrawn']}
  
  target: c.object({title: 'Target', required:['collection', 'id']}, {
    collection: { enum: patchables }
    id: c.objectId(title: 'Target ID') # search by this if not versioned

  # if target is versioned, want to know that info too
    original: c.objectId(title: 'Target Original') # search by this if versioned
    version:
      properties:
        major: { type: 'number', minimum: 0 }
        minor: { type: 'number', minimum: 0 }
  })
})

c.extendBasicProperties(PatchSchema, 'patch')

module.exports = PatchSchema
