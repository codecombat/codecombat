// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import c from './../schemas';

const LevelVersionSchema = c.object({required: ['original', 'majorVersion'], links: [{rel: 'db', href: '/db/level/{(original)}/version/{(majorVersion)}'}]}, {
  original: c.objectId(),
  majorVersion: {
    type: 'integer',
    minimum: 0
  }
}
);


const CodeLogSchema = {
  type: 'object',
  properties: {
    sessionID: c.objectId(),
    level: LevelVersionSchema,
    levelSlug: {type:'string'},
    userID: c.objectId(),
    log: {type:'string'},
    created: c.date()
  }
};

export default CodeLogSchema;
