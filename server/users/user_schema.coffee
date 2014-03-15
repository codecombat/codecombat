c = require '../commons/schemas'
emailSubscriptions = ['announcement', 'tester', 'level_creator', 'developer', 'article_editor', 'translator', 'support', 'notification']

UserSchema = c.object {},
  name: c.shortString({title: 'Display Name', default:''})
  email: c.shortString({title: 'Email', format: 'email'})
  firstName: c.shortString({title: 'First Name'})
  lastName: c.shortString({title: 'Last Name'})
  gender: {type: 'string', 'enum': ['male', 'female']}
  password: {type: 'string', maxLength: 256, minLength: 2, title:'Password'}
  passwordReset: {type: 'string'}
  photoURL: {type: 'string', format: 'url', required: false}

  facebookID: c.shortString({title: 'Facebook ID'})
  gplusID: c.shortString({title: 'G+ ID'})

  wizardColor1: c.pct({title: 'Wizard Clothes Color'})
  volume: c.pct({title: 'Volume'})
  music: {type: 'boolean', default: true}
  #autocastDelay, or more complex autocast options? I guess I'll see what I need when trying to hook up Scott's suggested autocast behavior

  emailSubscriptions: c.array {uniqueItems: true, 'default': ['announcement', 'notification']}, {'enum': emailSubscriptions}

  # server controlled
  permissions: c.array {'default': []}, c.shortString()
  dateCreated: c.date({title: 'Date Joined'})
  anonymous: {type: 'boolean', 'default': true}
  testGroupNumber: {type: 'integer', minimum: 0, maximum: 256, exclusiveMaximum: true}
  mailChimp: {type: 'object'}
  hourOfCode: {type: 'boolean'}
  hourOfCodeComplete: {type: 'boolean'}

  emailLower: c.shortString()
  nameLower: c.shortString()
  passwordHash: {type: 'string', maxLength: 256}

  # client side
  #gravatarProfile: {} (should only ever be kept locally)
  emailHash: {type: 'string'}

  #Internationalization stuff
  preferredLanguage: {type: 'string', default: 'en', 'enum': c.getLanguageCodeArray()}

  signedCLA: c.date({title: 'Date Signed the CLA'})
  wizard: c.object {},
    colorConfig: c.object {additionalProperties: c.colorConfig()}

  aceConfig: c.object {},
    keyBindings: {type: 'string', 'default': 'default', 'enum': ['default', 'vim', 'emacs']}
    invisibles: {type: 'boolean', 'default': false}
    indentGuides: {type: 'boolean', 'default': false}
    behaviors: {type: 'boolean', 'default': false}

c.extendBasicProperties UserSchema, 'user'

module.exports = UserSchema
