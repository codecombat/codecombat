// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('./../schemas');

const CLASubmissionSchema = c.object({
  title: 'CLA Submission',
  description: 'Recording when a user signed the CLA.'
});

_.extend(CLASubmissionSchema.properties, {
  user: c.objectId({links: [{rel: 'extra', href: '/db/user/{($)}'}]}),
  email: c.shortString({format: 'email'}),
  name: {type: 'string'},
  githubUsername: c.shortString(),
  created: c.date({title: 'Created', readOnly: true})
}
);

c.extendBasicProperties(CLASubmissionSchema, 'cla.submission');

module.exports = CLASubmissionSchema;
