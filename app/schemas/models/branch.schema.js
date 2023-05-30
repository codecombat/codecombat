// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import c from './../schemas';

const BranchSchema = {
  type: 'object',
  properties: {
    patches: {
      type: 'array',
      items: {
        type: 'object'
        // TODO: Link to Patch schema
      }
    },
    updated: c.stringDate(),
    updatedBy: c.objectId(),
    updatedByName: { type: 'string' }
  }
};

c.extendBasicProperties(BranchSchema, 'branches');
c.extendNamedProperties(BranchSchema);

export default BranchSchema;
