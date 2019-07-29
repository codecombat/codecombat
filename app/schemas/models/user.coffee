c = require './../schemas'
{FeatureAuthoritySchema, FeatureRecipientSchema} = require './feature.schema'

emailSubscriptions = ['announcement', 'tester', 'level_creator', 'developer', 'article_editor', 'translator', 'support', 'notification']

UserSchema = c.object
  title: 'User'
  default:
    visa: 'Authorized to work in the US'
    music: true
    name: 'Anonymous'
    autocastDelay: 5000
    emails: {}
    consentHistory: []
    permissions: []
    anonymous: true
    points: 0
    preferredLanguage: 'en-US'
    aceConfig: {}
    simulatedBy: 0
    simulatedFor: 0
    jobProfile: {}
    earned: {heroes: [], items: [], levels: [], gems: 0}
    purchased: {heroes: [], items: [], levels: [], gems: 0}

c.extendNamedProperties UserSchema  # let's have the name be the first property

#Put the various filters in variables for reusability
phoneScreenFilter =
  title: 'Phone screened'
  type: 'boolean'
  description: 'Whether the candidate has been phone screened.'
schoolFilter =
  title: 'School'
  type: 'string'
  enum: ['Top School', 'Other']
locationFilter =
  title: 'Location'
  type: 'string'
  enum: ['Bay Area', 'New York', 'Other US', 'International']
roleFilter =
  title: 'Role'
  type: 'string'
  enum: ['Web Developer', 'Software Developer', 'Mobile Developer']
seniorityFilter =
  title: 'Seniority'
  type: 'string'
  enum: ['College Student', 'Recent Grad', 'Junior', 'Senior']
visa = c.shortString
  title: 'US Work Status'
  description: 'Are you authorized to work in the US, or do you need visa sponsorship? (If you live in Canada or Australia, mark authorized.)'
  enum: ['Authorized to work in the US', 'Need visa sponsorship']

_.extend UserSchema.properties,
  email: c.shortString({title: 'Email', format: 'email'})
  emailVerified: { type: 'boolean' }
  iosIdentifierForVendor: c.shortString({format: 'hidden'})
  firstName: c.shortString({title: 'First Name'})
  lastName: c.shortString({title: 'Last Name'})
  gender: {type: 'string'} # , 'enum': ['male', 'female', 'secret', 'trans', 'other']
  # NOTE: ageRange enum changed on 4/27/16 from ['0-13', '14-17', '18-24', '25-34', '35-44', '45-100']
  ageRange: {type: 'string'}  # 'enum': ['13-15', '16-17', '18-24', '25-34', '35-44', '45-100']
  password: c.passwordString
  passwordReset: {type: 'string'}
  photoURL: {type: 'string', format: 'image-file', title: 'Profile Picture', description: 'Upload a 256x256px or larger image to serve as your profile picture.'}

  facebookID: c.shortString({title: 'Facebook ID'})
  githubID: {type: 'integer', title: 'GitHub ID'}
  gplusID: c.shortString({title: 'G+ ID'})
  cleverID: c.shortString({title: 'Clever ID'})
  oAuthIdentities: {
    description: 'List of OAuth identities this user has.'
    type: 'array'
    items: {
      description: 'A single OAuth identity'
      type: 'object'
      properties: {
        provider: c.objectId()
        id: { type: 'string', description: 'The service provider\'s id for the user' }
      }
    }
  }
  clientCreator: c.objectId({description: 'Client which created this user'})

  wizardColor1: c.pct({title: 'Wizard Clothes Color'})  # No longer used
  volume: c.pct({title: 'Volume'})
  music: { type: 'boolean' }
  autocastDelay: { type: 'integer' }  # No longer used
  lastLevel: { type: 'string' }
  heroConfig: c.HeroConfigSchema

  emailSubscriptions: c.array {uniqueItems: true}, {'enum': emailSubscriptions}  # Deprecated
  emails: c.object {title: 'Email Settings', default: generalNews: {enabled: true}, anyNotes: {enabled: true}, recruitNotes: {enabled: true} },
    # newsletters
    generalNews: {$ref: '#/definitions/emailSubscription'}
    adventurerNews: {$ref: '#/definitions/emailSubscription'}
    ambassadorNews: {$ref: '#/definitions/emailSubscription'}
    archmageNews: {$ref: '#/definitions/emailSubscription'}
    artisanNews: {$ref: '#/definitions/emailSubscription'}
    diplomatNews: {$ref: '#/definitions/emailSubscription'}
    teacherNews: {$ref: '#/definitions/emailSubscription'}
    scribeNews: {$ref: '#/definitions/emailSubscription'}

    # notifications
    anyNotes: {$ref: '#/definitions/emailSubscription'} # overrides any other notifications settings
    recruitNotes: {$ref: '#/definitions/emailSubscription'}
    employerNotes: {$ref: '#/definitions/emailSubscription'}

    oneTimes: c.array {title: 'One-time emails'},
      c.object {title: 'One-time email', required: ['type', 'email']},
        type: c.shortString() # E.g 'share progress modal parent'
        email: c.shortString()
        sent: c.date() # Set when sent
  unsubscribedFromMarketingEmails: { type: 'boolean' }

  consentHistory: c.array {title: 'History of consent actions'},
    c.object {title: 'Consent action', required: ['action', 'date', 'type']},
      action: {type: 'string', 'enum': ['allow', 'forbid']}
      date: c.date()
      type: c.shortString() # E.g 'email'
      emailHash: {type: 'string', maxLength: 128, minLength: 128, title: 'Hash of lower-case email address at the time'}
      description: c.shortString()

  # server controlled
  permissions: c.array {}, c.shortString()
  dateCreated: c.date({title: 'Date Joined'})
  anonymous: {type: 'boolean' }
  testGroupNumber: {type: 'integer', minimum: 0, maximum: 256, exclusiveMaximum: true}
  testGroupNumberUS: {type: 'integer', minimum: 0, maximum: 256, exclusiveMaximum: true}
  mailChimp: {type: 'object'}
  hourOfCode: {type: 'boolean'}
  hourOfCodeComplete: {type: 'boolean'}
  createdOnHost: { type: 'string' }

  emailLower: c.shortString()
  nameLower: c.shortString()
  passwordHash: {type: 'string', maxLength: 256}

  # client side
  emailHash: {type: 'string'}

  #Internationalization stuff
  preferredLanguage: {'enum': [null].concat(c.getLanguageCodeArray())}

  signedCLA: c.date({title: 'Date Signed the CLA'})

  # Legacy customizable wizard from a very early version of the game.
  wizard: c.object {},
    colorConfig: c.object {additionalProperties: c.colorConfig()}

  ozariaHeroConfig: c.object(
    {
      title: 'Player Ozaria Customization',
      description: 'Player customization options, including hero name, objectId and applied color tints.'
    }, {
      cinematicThangTypeOriginal: c.stringID(links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], title: 'Thang Type', description: 'The ThangType of the hero.', format: 'thang-type'),
      playerHeroName: c.shortString({ title: 'Ozaria Hero Name', description: 'The user set name for the ozaria hero. Used in cinematics.' }),
      tints: c.array(
        {
          title: 'Tints',
          description: 'Array of possible tints'
        },
        c.object({
          title: 'tintGroup',
          description: 'Duplicate data that would be found in a tint',
          required: ['slug', 'colorGroups']
        }, {
          slug: c.shortString({
            title: 'Tint Slug',
          }),
          colorGroups: c.object({ additionalProperties: c.colorConfig() })
        }))
      avatar: c.object({
        title: '1FH Avatar Choice',
        description: 'The 1FH avatar that was chosen by the user'
      }, {
        thangId: c.stringID(links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], title: 'Avatar ThangType', description: 'The in-level avatar thangType', format: 'thang-type'),
        cinematicThangId: c.stringID(links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], title: 'Cinematic ThangType', description: 'The cinematic avatar thangType', format: 'thang-type'),
      })
    })

  aceConfig: c.object { default: { language: 'python', keyBindings: 'default', invisibles: false, indentGuides: false, behaviors: false, liveCompletion: true }},
    language: {type: 'string', 'enum': ['python', 'javascript', 'coffeescript', 'clojure', 'lua', 'java', 'io']}
    keyBindings: {type: 'string', 'enum': ['default', 'vim', 'emacs']}  # Deprecated 2016-05-30; now we just always give them 'default'.
    invisibles: {type: 'boolean' }
    indentGuides: {type: 'boolean' }
    behaviors: {type: 'boolean' }
    liveCompletion: {type: 'boolean' }

  simulatedBy: {type: 'integer', minimum: 0 }
  simulatedFor: {type: 'integer', minimum: 0 }

  googleClassrooms: c.array { title: 'Google classrooms for the teacher' },
    c.object { required: ['name', 'id'] },
      id: { type: 'string' }
      name: { type: 'string' }
      importedToCoco: { type: 'boolean', default: false }

  importedBy: c.objectId { description: 'User ID of the teacher who imported this user' }

  points: {type: 'number'}
  activity: {type: 'object', description: 'Summary statistics about user activity', additionalProperties: c.activity}
  stats: c.object {additionalProperties: false},
    gamesCompleted: c.int()
    articleEdits: c.int()
    levelEdits: c.int()
    levelSystemEdits: c.int()
    levelComponentEdits: c.int()
    thangTypeEdits: c.int()
    patchesSubmitted: c.int
      description: 'Amount of patches submitted, not necessarily accepted'
    patchesContributed: c.int
      description: 'Amount of patches submitted and accepted'
    patchesAccepted: c.int
      description: 'Amount of patches accepted by the user as owner'
    # The below patches only apply to those that actually got accepted
    totalTranslationPatches: c.int()
    totalMiscPatches: c.int()
    articleTranslationPatches: c.int()
    articleMiscPatches: c.int()
    levelTranslationPatches: c.int()
    levelMiscPatches: c.int()
    levelComponentTranslationPatches: c.int()
    levelComponentMiscPatches: c.int()
    levelSystemTranslationPatches: c.int()
    levelSystemMiscPatches: c.int()
    thangTypeTranslationPatches: c.int()
    thangTypeMiscPatches: c.int()
    achievementTranslationPatches: c.int()
    achievementMiscPatches: c.int()
    pollTranslationPatches: c.int()
    pollMiscPatches: c.int()
    campaignTranslationPatches: c.int()
    campaignMiscPatches: c.int()
    courseTranslationPatches: c.int()
    courseMiscPatches: c.int()
    courseEdits: c.int()
    concepts: {type: 'object', additionalProperties: c.int(), description: 'Number of levels completed using each programming concept.'}
    licenses: c.object { additionalProperties: true }
    students: c.object { additionalProperties: true }

  earned: c.RewardSchema 'earned by achievements'
  purchased: c.RewardSchema 'purchased with gems or money'
  deleted: {type: 'boolean'}
  dateDeleted: c.date()
  doNotDeleteEU: c.date()
  spent: {type: 'number'}
  stripeCustomerID: { type: 'string' } # TODO: Migrate away from this property

  payPal: c.object {}, {
    payerID: { type: 'string' }
    billingAgreementID: { type: 'string', description: 'Set if user has PayPal monthly subscription' }
    subscribeDate: c.date()
    cancelDate: c.date()
  }

  stripe: c.object {}, {
    customerID: { type: 'string' }
    planID: { enum: ['basic'], description: 'Determines if a user has or wants to subscribe' }
    subscriptionID: { type: 'string', description: 'Determines if a user is subscribed' }
    token: { type: 'string' }
    couponID: { type: 'string' }

    # TODO: move `free` out of stripe, it's independent
    free: { type: ['boolean', 'string'], format: 'date-time', description: 'Type string is subscription end date' }
    prepaidCode: c.shortString description: 'Prepaid code to apply to sub purchase'

    # Sponsored subscriptions
    subscribeEmails: c.array { description: 'Input for subscribing other users' }, c.shortString()
    unsubscribeEmail: { type: 'string', description: 'Input for unsubscribing a sponsored user' }
    recipients: c.array { title: 'Recipient subscriptions owned by this user' },
      c.object { required: ['userID', 'subscriptionID'] },
        userID: c.objectId { description: 'User ID of recipient' }
        subscriptionID: { type: 'string' }
        couponID: { type: 'string' }
    sponsorID: c.objectId { description: "User ID that owns this user's subscription" }
    sponsorSubscriptionID: { type: 'string', description: 'Sponsor aggregate subscription used to pay for all recipient subs' }
  }

  siteref: { type: 'string' }
  referrer: { type: 'string' }
  country: { type: 'string' }  # Set on new users for certain countries on the server - keeping this field although it is same as geo.countryName since user.country is already being used in other files, TODO: Refactor the code to remove this in future
  geo: c.object {}, {
    country: { description:'2 letter ISO-3166-1 country code' }
    countryName: { description: 'Full country name'}
    region: { description:'2 character region code' }
    city: { description:'Full city name' }
    ll: c.array {}, { description: 'Latitude and longitude of the city'}
    metro: { description: 'Metro code'}
    zip: { description: 'Postal code'}
  }

  clans: c.array {}, c.objectId()
  courseInstances: c.array {}, c.objectId()
  currentCourse: c.object {}, {  # Old, can be removed after we deploy and delete it from all users
    courseID: c.objectId({})
    courseInstanceID: c.objectId({})
  }
  coursePrepaidID: c.objectId({
    description: 'Prepaid which has paid for this user\'s course access'
  })
  coursePrepaid: {
    type: 'object'
    properties: {
      _id: c.objectId()
      startDate: c.stringDate()
      endDate: c.stringDate()
      type: { type: ['string', 'null'] }
      includedCourseIDs: { type: ['array', 'null'], description: 'courseIDs that this prepaid includes access to', items: c.objectId() }
    }
  }
  enrollmentRequestSent: { type: 'boolean', description: 'deprecated' }

  schoolName: {type: 'string', description: 'Deprecated string. Use "school" object instead.'}
  role: {type: 'string', enum: ["advisor", "parent", "principal", "student", "superintendent", "teacher", "technology coordinator", "possible teacher"]}  # unset: home player
  verifiedTeacher: { type: 'boolean' }
  birthday: ({ type: 'string', title: "Birthday", description: "Just month and year, stored YYYY-MM"})
  lastAchievementChecked: c.stringDate({ name: 'Last Achievement Checked' })

  israelId: {type: 'string', description: 'ID string used just for il.codecombat.com'}
  school: {
    type: 'object',
    description: 'Generic property for storing school information. Currently
                  only used by Israel; if/when we use it for other purposes,
                  think about how to keep the data consistent.',
    properties: {
      name: { type: 'string' }
      city: { type: 'string' }
      district: { type: 'string' }
      state: { type: 'string' }
      country: { type: 'string' }
    }
  }
  lastAnnouncementSeen:
    type: 'number'
    description: 'The highed announcement modal index displayed to the user.'
  studentMilestones:
    type: 'object'
    description: "Flags for whether a teacher's students have reached a given level. Used for Intercom campaigns."
    properties: {
      studentStartedWakkaMaul: { type: 'boolean', description: "One of a teacher's students has reached Wakka Maul" }
      studentStartedMayhemOfMunchkins: { type: 'boolean', description: "One of a teacher's students has started A Mayhem of Munchkins" }
      # TODO: refactor above two properties to be integers
      studentsStartedDungeonsOfKithgard: { type: 'integer', description: "The number of a teacher's students who have started Dungeons of Kithgard" }
      studentsStartedTrueNames: { type: 'integer', description: "The number of a teacher's students who have started True Names" }
    }

  administratedTeachers: c.array {}, c.objectId()
  administratingTeachers: c.array {}, c.objectId()

  features:
    type: 'object'
    title: 'Feature Flags'
    properties:
      authority:
        type: 'object'
        description: 'Feature flags applied to associated users'
        # key is the feature id
        additionalProperties: FeatureAuthoritySchema
      recipient:
        type: 'object'
        description: 'Features flags applied to this user'
        # key is the feature id
        additionalProperties: FeatureRecipientSchema

c.extendBasicProperties UserSchema, 'user'

UserSchema.definitions =
  emailSubscription: c.object { default:  { enabled: true, count: 0 } }, {
    enabled: {type: 'boolean'}
    lastSent: c.date()
    count: {type: 'integer'}
  }

module.exports = UserSchema
