const c = require('./../schemas')
const { FeatureAuthoritySchema, FeatureRecipientSchema } = require('./feature.schema')

const emailSubscriptions = ['announcement', 'tester', 'level_creator', 'developer', 'article_editor', 'translator', 'support', 'notification']

const UserSchema = c.object({
  title: 'User',
  default: {
    visa: 'Authorized to work in the US',
    music: true,
    name: 'Anonymous',
    autocastDelay: 5000,
    emails: {},
    consentHistory: [],
    permissions: [],
    anonymous: true,
    points: 0,
    preferredLanguage: 'en-US',
    aceConfig: {},
    simulatedBy: 0,
    simulatedFor: 0,
    jobProfile: {},
    earned: { heroes: [], items: [], levels: [], gems: 0 },
    purchased: { heroes: [], items: [], levels: [], gems: 0 }
  }
})

c.extendNamedProperties(UserSchema) // let's have the name be the first property

_.extend(UserSchema.properties, {
  email: c.shortString({ title: 'Email', format: 'email' }),
  emailVerified: { type: 'boolean' },
  iosIdentifierForVendor: c.shortString({ format: 'hidden' }),
  firstName: c.shortString({ title: 'First Name', not: { pattern: 'Q204384420' } }),
  lastName: c.shortString({ title: 'Last Name', not: { pattern: 'Q204384420' } }),
  gender: { type: 'string' }, // , 'enum': ['male', 'female', 'secret', 'trans', 'other']
  // NOTE: ageRange enum changed on 4/27/16 from ['0-13', '14-17', '18-24', '25-34', '35-44', '45-100']
  ageRange: { type: 'string' }, // 'enum': ['13-15', '16-17', '18-24', '25-34', '35-44', '45-100']
  password: c.passwordString,
  passwordReset: { type: 'string' },
  passwordResetExpires: c.date(),
  newPasswordRequired: { type: 'boolean' }, // Whether the user needs to set a new password
  photoURL: { type: 'string', format: 'image-file', title: 'Profile Picture', description: 'Upload a 256x256px or larger image to serve as your profile picture.' },

  facebookID: c.shortString({ title: 'Facebook ID' }),
  githubID: { type: 'integer', title: 'GitHub ID' },
  gplusID: c.shortString({ title: 'G+ ID' }),
  cleverID: c.shortString({ title: 'Clever ID' }),
  edLinkID: c.shortString({ title: 'Clever ID' }),
  oAuthIdentities: {
    description: 'List of OAuth identities this user has.',
    type: 'array',
    items: {
      description: 'A single OAuth identity',
      type: 'object',
      properties: {
        provider: c.objectId(),
        id: { type: 'string', description: 'The service provider\'s id for the user' }
      }
    }
  },
  clientCreator: c.objectId({ description: 'Client which created this user' }),
  clientPermissions: {
    description: 'More APIClients with permissions on this user, apart from clientCreator.',
    type: 'array',
    items: {
      type: 'object',
      additionalProperties: false,
      properties: {
        client: c.objectId({ description: 'APIClient with permissions on this user' }),
        access: { type: 'string', enum: ['read', 'grant', 'write', 'owner'] }
      }
    }, // 'grant' permissions allow APIClients to grant licenses to a user
    format: 'hidden'
  },

  wizardColor1: c.pct({ title: 'Wizard Clothes Color' }), // No longer used
  volume: c.pct({ title: 'Volume' }),
  music: { type: 'boolean' },
  autocastDelay: { type: 'integer' }, // No longer used
  lastLevel: { type: 'string' },
  heroConfig: c.HeroConfigSchema,

  emailSubscriptions: c.array({ uniqueItems: true }, { enum: emailSubscriptions }), // Deprecated
  emails: c.object({ title: 'Email Settings', default: { generalNews: { enabled: true }, anyNotes: { enabled: true }, recruitNotes: { enabled: true } } }, {
    // newsletters
    generalNews: { $ref: '#/definitions/emailSubscription' },
    adventurerNews: { $ref: '#/definitions/emailSubscription' },
    ambassadorNews: { $ref: '#/definitions/emailSubscription' },
    archmageNews: { $ref: '#/definitions/emailSubscription' },
    artisanNews: { $ref: '#/definitions/emailSubscription' },
    diplomatNews: { $ref: '#/definitions/emailSubscription' },
    teacherNews: { $ref: '#/definitions/emailSubscription' },
    scribeNews: { $ref: '#/definitions/emailSubscription' },

    // notifications
    anyNotes: { $ref: '#/definitions/emailSubscription' }, // overrides any other notifications settings
    recruitNotes: { $ref: '#/definitions/emailSubscription' },
    employerNotes: { $ref: '#/definitions/emailSubscription' },

    oneTimes: c.array({ title: 'One-time emails' },
      c.object({ title: 'One-time email', required: ['type', 'email'] }, {
        type: c.shortString(), // E.g 'share progress modal parent'
        email: c.shortString(),
        sent: c.date()
      }
      )
    ), // Set when sent

    validations: c.array
  }, { title: 'Sendgrid email validation results' },
  c.object({}, {
    validationDate: c.date(),
    result: c.object({ additionalProperties: true })
  }
  )
  ),

  unsubscribedFromMarketingEmails: { type: 'boolean' },

  consentHistory: c.array({ title: 'History of consent actions' },
    c.object({ title: 'Consent action', required: ['action', 'date', 'type'] }, {
      action: { type: 'string', enum: ['allow', 'forbid'] },
      date: c.date(),
      type: c.shortString(), // E.g 'email'
      emailHash: { type: 'string', maxLength: 128, minLength: 128, title: 'Hash of lower-case email address at the time' },
      description: c.shortString()
    }
    )
  ),

  // server controlled
  permissions: c.array({}, c.shortString()),
  dateCreated: c.date({ title: 'Date Joined' }),
  anonymous: { type: 'boolean' },
  testGroupNumber: { type: 'integer', minimum: 0, maximum: 256, exclusiveMaximum: true },
  testGroupNumberUS: { type: 'integer', minimum: 0, maximum: 256, exclusiveMaximum: true },
  experiments: c.array({ description: 'A/B tests this user is a part of' }, {
    // eslint-disable-next-line no-useless-escape
    name: c.shortString({ description: 'Experiment name, like "long-subscription-choice"', pattern: '^[a-z][\-a-z0-9]*$' }), // Slug-like
    value: { description: 'The experiment value/group that this user is assigned to', additionalProperties: true }, // Data type is flexible depending on experiment needs
    probability: c.pct({ description: 'Probability of being assigned to this experiment value' }),
    startDate: c.date({ description: 'When this user first started the experiment' })
  }),
  mailChimp: { type: 'object' },
  hourOfCode: { type: 'boolean' },
  hourOfCode2019: { type: 'boolean' }, // adding for hoc 2019, TODO refactor into a reusable property if needed
  hourOfCodeComplete: { type: 'boolean' },
  hourOfCodeOptions: c.object({ title: 'Options useful for hour of code users' }, {
    showCompleteSignupModal: { type: 'boolean', description: 'Whether to show complete signup modal on teacher dashboard - only valid for teachers who signup from hoc signup flow' },
    showHocProgress: { type: 'boolean', description: 'Set true for students who sign up from hoc save progress modal since they didnt have a class code' },
    hocCodeLanguage: { type: 'string', description: 'HoC code language played as anonymous student, used to show progress on student dashboard until they have a class code' }
  }),
  createdOnHost: { type: 'string' },

  emailLower: c.shortString(),
  nameLower: c.shortString(),
  passwordHash: { type: 'string', maxLength: 256 },

  // client side
  emailHash: { type: 'string' },

  // Internationalization stuff
  preferredLanguage: { enum: [null].concat(c.getLanguageCodeArray()) },

  signedCLA: c.date({ title: 'Date Signed the CLA' }),

  // Legacy customizable wizard from a very early version of the game.
  wizard: c.object({},
    { colorConfig: c.object({ additionalProperties: c.colorConfig() }) }),

  ozariaUserOptions: c.object(
    {
      title: 'Player Ozaria Customization',
      description: 'Player customization options, including hero name, objectId and applied color tints.'
    }, {
      isometricThangTypeOriginal: c.stringID({ links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], title: 'Thang Type', description: 'The isometric ThangType of the hero.', format: 'thang-type' }),
      cinematicThangTypeOriginal: c.stringID({ links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], title: 'Cinematic Thang Type', description: 'The cinematic ThangType of the hero.', format: 'thang-type' }),
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
            title: 'Tint Slug'
          }),
          colorGroups: c.object({ additionalProperties: c.colorConfig() })
        })),
      avatar: c.object({
        title: 'CH1 Avatar Choice',
        description: 'The CH1 avatar that was chosen by the user'
      }, {
        cinematicThangTypeId: c.stringID({ links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], title: 'Cinematic ThangType', description: 'The cinematic avatar thangType original Id', format: 'thang-type' }),
        cinematicPetThangId: c.stringID({ links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], title: 'Cinematic Pet ThangType', description: 'The cinematic avatar pet thangType original Id', format: 'thang-type' }),
        avatarCodeString: c.shortString({ title: 'Avatar Capstone String', description: 'The string representation of the avatar for the capstone.' })
      })
    }),

  aceConfig: c.object({ default: { language: 'python', keyBindings: 'default', invisibles: false, indentGuides: false, behaviors: false, liveCompletion: true } }, {
    language: { type: 'string', enum: ['python', 'javascript', 'coffeescript', 'lua', 'java', 'cpp'] },
    keyBindings: { type: 'string', enum: ['default', 'vim', 'emacs'] }, // Deprecated 2016-05-30; now we just always give them 'default'.
    invisibles: { type: 'boolean' },
    indentGuides: { type: 'boolean' },
    behaviors: { type: 'boolean' },
    liveCompletion: { type: 'boolean' },
    screenReaderMode: { type: 'boolean' },
    codeFormat: { type: 'string', enum: ['blocks-icons', 'blocks-text', 'blocks-and-code', 'text-code'], description: 'Default code format option. Default if unset: text-code.' },
    preferWideEditor: { type: 'boolean', description: 'Whether the user prefers a wide editor.' }
  }),

  simulatedBy: { type: 'integer', minimum: 0 },
  simulatedFor: { type: 'integer', minimum: 0 },

  googleClassrooms: c.array({ title: 'Google classrooms for the teacher' },
    c.object({ required: ['name', 'id'] }, {
      id: { type: 'string' },
      name: { type: 'string' },
      importedToCoco: { type: 'boolean', default: false },
      importedToOzaria: { type: 'boolean', default: false },
      deletedFromGC: { type: 'boolean', default: false, description: 'Set true for classrooms imported to coco/ozaria but deleted from GC' }
    })),

  importedBy: c.objectId({ description: 'User ID of the teacher who imported this user' }),
  googleCalendarEvents: c.array({ title: 'Google calendar events for the online teacher' },
    c.object({ required: ['summary'] }, {
      summary: { type: 'string' },
      importedToCoco: { type: 'boolean', default: false },
      deletedFromGC: { type: 'boolean', default: false, description: 'Set true for events imported to coco but deleted from GC' }
    })),

  points: { type: 'number' },
  activity: { type: 'object', description: 'Summary statistics about user activity', additionalProperties: c.activity },
  stats: c.object({ additionalProperties: false }, {
    gamesCompleted: c.int(),
    articleEdits: c.int(),
    levelEdits: c.int(),
    levelSystemEdits: c.int(),
    levelComponentEdits: c.int(),
    thangTypeEdits: c.int(),
    patchesSubmitted: c.int({ description: 'Amount of patches submitted, not necessarily accepted' }),
    patchesContributed: c.int({ description: 'Amount of patches submitted and accepted' }),
    patchesAccepted: c.int({ description: 'Amount of patches accepted by the user as owner' }),
    // The below patches only apply to those that actually got accepted
    totalTranslationPatches: c.int(),
    totalMiscPatches: c.int(),
    articleTranslationPatches: c.int(),
    articleMiscPatches: c.int(),
    levelTranslationPatches: c.int(),
    levelMiscPatches: c.int(),
    levelComponentTranslationPatches: c.int(),
    levelComponentMiscPatches: c.int(),
    levelSystemTranslationPatches: c.int(),
    levelSystemMiscPatches: c.int(),
    thangTypeTranslationPatches: c.int(),
    thangTypeMiscPatches: c.int(),
    achievementTranslationPatches: c.int(),
    achievementMiscPatches: c.int(),
    pollTranslationPatches: c.int(),
    pollMiscPatches: c.int(),
    campaignTranslationPatches: c.int(),
    campaignMiscPatches: c.int(),
    courseTranslationPatches: c.int(),
    courseMiscPatches: c.int(),
    courseEdits: c.int(),
    cinematicTranslationPatches: c.int(),
    cinematicMiscPatches: c.int(),
    cinematicEdits: c.int(),
    interactiveTranslationPatches: c.int(),
    interactiveMiscPatches: c.int(),
    interactiveEdits: c.int(),
    concepts: { type: 'object', additionalProperties: c.int(), description: 'Number of levels completed using each programming concept.' },
    licenses: c.object({ additionalProperties: true }),
    students: c.object({ additionalProperties: true }),
    codePoints: c.int({ title: 'CodePoints', minimum: 0, description: 'Total CodePoints earned' })
  }),

  earned: c.RewardSchema('earned by achievements'),
  purchased: c.RewardSchema('purchased with gems or money'),
  deleted: { type: 'boolean' },
  dateDeleted: c.date(),
  doNotDeleteEU: c.date(),
  spent: { type: 'number' },
  stripeCustomerID: { type: 'string' }, // TODO: Migrate away from this property

  payPal: c.object({}, {
    payerID: { type: 'string' },
    billingAgreementID: { type: 'string', description: 'Set if user has PayPal monthly subscription' },
    subscribeDate: c.date(),
    cancelDate: c.date()
  }),

  stripe: c.object({}, {
    customerID: { type: 'string' },
    planID: { type: 'string', description: 'Determines if a user has or wants to subscribe. Matches subscription plan on stripe.' },
    subscriptionID: { type: 'string', description: 'Determines if a user is subscribed' },
    token: { type: 'string' },
    couponID: { type: 'string' },
    currency: { type: 'string' },

    // TODO: move `free` out of stripe, it's independent
    free: {
      oneOf: [
        { type: 'string', format: 'date-time', description: 'Type string is subscription end date' },
        { type: 'boolean', description: 'Type boolean is whether the subscription is free or not' }
      ]
    },
    prepaidCode: c.shortString({ description: 'Prepaid code to apply to sub purchase' }),

    // Sponsored subscriptions
    subscribeEmails: c.array({ description: 'Input for subscribing other users' }, c.shortString()),
    unsubscribeEmail: { type: 'string', description: 'Input for unsubscribing a sponsored user' },
    recipients: c.array({ title: 'Recipient subscriptions owned by this user' },
      c.object({ required: ['userID', 'subscriptionID'] }, {
        userID: c.objectId({ description: 'User ID of recipient' }),
        subscriptionID: { type: 'string' },
        couponID: { type: 'string' }
      })),
    sponsorID: c.objectId({ description: "User ID that owns this user's subscription" }),
    sponsorSubscriptionID: { type: 'string', description: 'Sponsor aggregate subscription used to pay for all recipient subs' }
  }),

  siteref: { type: 'string' },
  referrer: { type: 'string' },
  country: { type: 'string' }, // Set on new users for certain countries on the server - keeping this field although it is same as geo.countryName since user.country is already being used in other files, TODO: Refactor the code to remove this in future
  geo: c.object({}, {
    country: { description: '2 letter ISO-3166-1 country code' },
    countryName: { description: 'Full country name' },
    region: { description: '2 character region code' },
    city: { description: 'Full city name' },
    ll: c.array({}, { description: 'Latitude and longitude of the city' }),
    metro: { description: 'Metro code' },
    zip: { description: 'Postal code' },
    timeZone: { description: 'Timezone' }
  }),

  clans: c.array({}, c.objectId()),
  courseInstances: c.array({}, c.objectId()),
  currentCourse: c.object({}, { // Old, can be removed after we deploy and delete it from all users
    courseID: c.objectId({}),
    courseInstanceID: c.objectId({})
  }),
  coursePrepaidID: c.objectId({
    description: 'Prepaid which has paid for this user\'s course access'
  }),
  coursePrepaid: {
    type: 'object',
    properties: {
      _id: c.objectId(),
      startDate: c.stringDate(),
      endDate: c.stringDate(),
      type: { type: ['string', 'null'] },
      includedCourseIDs: { type: ['array', 'null'], description: 'courseIDs that this prepaid includes access to', items: c.objectId() },
      migrated: { type: 'boolean' }
    }
  },
  enrollmentRequestSent: { type: 'boolean', description: 'deprecated' },

  schoolName: { type: 'string', description: 'Deprecated string. Use "school" object instead.' },
  role: { type: 'string', enum: ['advisor', 'parent', 'principal', 'student', 'superintendent', 'teacher', 'technology coordinator', 'possible teacher', 'parent-home'] }, // unset: home player
  verifiedTeacher: { type: 'boolean' },
  birthday: ({ type: 'string', title: 'Birthday', description: 'Just month and year, stored YYYY-MM' }),
  lastAchievementChecked: c.stringDate({ name: 'Last Achievement Checked' }),

  israelId: { type: 'string', description: 'ID string used just for il.codecombat.com' },
  school: {
    type: 'object',
    description: 'Generic property for storing school information. Currently \n' +
'only used by Israel; if/when we use it for other purposes, \n' +
'think about how to keep the data consistent.',
    properties: {
      name: { type: 'string' },
      city: { type: 'string' },
      district: { type: 'string' },
      state: { type: 'string' },
      country: { type: 'string' }
    }
  },
  lastAnnouncementSeen: {
    type: 'number',
    description: 'The highed announcement modal index displayed to the user.'
  },
  lastAnnouncementGen: c.date,
  studentMilestones: {
    type: 'object',
    description: "Flags for whether a teacher's students have reached a given level. Used for Intercom campaigns.",
    properties: {
      studentStartedWakkaMaul: { type: 'boolean', description: "One of a teacher's students has reached Wakka Maul" },
      studentStartedMayhemOfMunchkins: { type: 'boolean', description: "One of a teacher's students has started A Mayhem of Munchkins" },
      // TODO: refactor above two properties to be integers
      studentsStartedDungeonsOfKithgard: { type: 'integer', description: "The number of a teacher's students who have started Dungeons of Kithgard" },
      studentsStartedTrueNames: { type: 'integer', description: "The number of a teacher's students who have started True Names" }
    }
  },
  administratedTeachers: c.array({}, c.objectId()),
  administratingTeachers: c.array({}, c.objectId()),

  seenNewDashboardModal: { type: 'boolean', description: 'Whether the user has seen the new dashboard onboarding modal? Set to true after the modal is seen and closed by the user' }, // Ozaria
  closedNewTDGetStartedTooltip: { type: 'boolean', description: 'Whether the user has closed the get started tooltip in the new dashboard? Set to true once the user has dismissed the tooltip' }, // Ozaria

  seenPromotions: {
    type: 'object',
    properties: {
      'hackstack-beta-release-modal': c.date(),
      'curriculum-sidebar-promotion-modal': c.date(),
      'hp-junior-modal': c.date()
    }
  },

  features: {
    type: 'object',
    title: 'Feature Flags',
    properties: {
      authority: {
        type: 'object',
        description: 'Feature flags applied to associated users',
        // key is the feature id
        additionalProperties: FeatureAuthoritySchema
      },
      recipient: {
        type: 'object',
        description: 'Features flags applied to this user',
        // key is the feature id
        additionalProperties: FeatureRecipientSchema
      },
      isNewDashboardActive: {
        type: 'boolean'
      },
      ownerDistrictId: c.objectId({ description: 'District ID where user has admin permission to view data like outcome reports' }),
      syncedToSF: { type: 'boolean', description: 'Whether the user has been synced to Salesforce' },
      syncedToCIO: { type: 'boolean', description: 'Whether the user has been synced to CIO' }
    }
  },

  archived: c.date({ description: 'Marks this record for automatic online archiving to cold storage by our cloud database.' }),
  products: c.array({ title: 'Products purchased or used by this user' },
    c.object({ required: ['product', 'startDate', 'recipient', 'paymentService', 'paymentDetails'], additionalProperties: true }, {
      // ensure we can add additionalProperties
      product: { type: 'string', enum: ['course', 'basic_subscription', 'pd', 'esports', 'online-classes'], decription: 'The "name" field for the product purchased' }, // And/or the ID of the Product in the database, if we make a Product for each thing we can buy?

      prepaid: c.objectId({ links: [{ rel: 'db', href: '/db/prepaid/{($)}' }] }), // required for type: “course” for legacy compatibility, optional for other types, consider putting into productOptions
      productOptions: {
        anyOf: [
          c.object({ additionalProperties: true }, { // course
            includedCourseIDs: {
              type: ['array', 'null']
            }
          }),
          c.object({}, { // esports
            type: { type: 'string', enum: ['basic', 'pro'] },
            id: { type: 'string' },
            teams: { type: ['number', 'null'] },
            tournaments: { type: ['number', 'null'] },
            createdTournaments: { type: ['number', 'null'] },
            arenas: { type: ['string', 'null'] }
          }),
          c.object({}, { // online-classes
            event: c.objectId({ links: [{ rel: 'db', href: '/db/event/{($)}' }] }),
            count: { type: 'number' }
          })
        ]
      },
      startDate: c.date(),
      endDate: c.date(), // TODO: optional indication of no end date (lasts forever) - or do we just leave unset?
      purchaser: c.objectId({ links: [{ rel: 'extra', href: '/db/user/{($)}' }] }), // in case of gifts
      recipient: c.objectId({ links: [{ rel: 'extra', href: '/db/user/{($)}' }] }),
      purchaserDesc: {
        detailType: { enum: ['email', 'phone'] },
        detail: c.shortString({ description: 'We may have a purchaser with no account, in which case only this email/phone/... will be set' })
      },
      paymentService: { enum: ['stripe', 'testing', 'free', 'api', 'external', 'paypal'] }, // Removed 'ios', could perhaps remove 'paypal', could differentiate 'external' further
      paymentDetails:
        c.object({ additionalProperties: true }, {
          allOf: {
            purchaseDate: c.date(), // TODO: separate payment date and invoice date (esp. online classes)?
            amount: { type: 'integer', description: 'Payment in cents on US server and in RMB cents on the China server' },
            currency: { type: 'string' },
            // Do we need something about autorenewal / frequency here?
            oneOf: [
              { stripeCustomerId: { type: 'string' }, subscriptionId: { type: 'string' }, paymentSession: c.objectId({ links: [{ rel: 'extra', href: '/db/payment.session/{($)}' }] }) }, // TODO: other various Stripe-specific options
              { paypalCustomerId: { type: 'string' } }, // TODO: various PayPal-specific options, if we keep PayPal
              { staffCreator: c.objectId({ links: [{ rel: 'extra', href: '/db/user/{($)}' }] }) } // any other external payment source options?
              // ... etc. for each possible payment service ...
            ]
          }
        })
    })),
  edLink: c.object({}, {
    profileId: { type: 'string' },
    refreshToken: { type: 'string', description: 'token to get access token to get user details' },
    identifiers: c.array({ description: 'identifiers to canvas, clever etc' },
      c.object({}, {
        iType: { type: 'string' },
        iValue: { type: 'string' }
      }))
  }),
  library: c.object({}, {
    profileId: { type: 'string' },
    name: { type: 'string', description: 'name of library for the user' }
  }),
  related: c.array(
    { description: 'related accounts to this user' },
    c.object(
      {},
      {
        userId: c.objectId({ description: 'userId of the account currentUser is related to' }),
        verified: { type: 'boolean', description: 'whether linking is verified/authenticated' },
        relation: c.shortString({ description: 'relation of this user to related one' }),
        code: c.shortString({ description: 'confirmation code for linking user' })
      }
    )
  ),
  referrerTrack: c.object({ description: 'utm_source, medium etc - anything to track from where user came to Coco' }, {
    source: { type: 'string' },
    medium: { type: 'string' },
    campaign: { type: 'string' }
  })
})

c.extendBasicProperties(UserSchema, 'user')

UserSchema.definitions = {
  emailSubscription: c.object({ default: { enabled: true, count: 0 } }, {
    enabled: { type: 'boolean' },
    lastSent: c.date(),
    count: { type: 'integer' }
  })
}

module.exports = UserSchema
