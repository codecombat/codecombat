c = require './../schemas'
emailSubscriptions = ['announcement', 'tester', 'level_creator', 'developer', 'article_editor', 'translator', 'support', 'notification']

UserSchema = c.object
  title: 'User'
  default:
    visa: 'Authorized to work in the US'
    music: true
    name: 'Anonymous'
    autocastDelay: 5000
    emails: {}
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

  emailSubscriptions: c.array {uniqueItems: true}, {'enum': emailSubscriptions}
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
        type: c.shortString() # E.g 'subscribe modal parent'
        email: c.shortString()
        sent: c.date() # Set when sent

  # server controlled
  permissions: c.array {}, c.shortString()
  dateCreated: c.date({title: 'Date Joined'})
  anonymous: {type: 'boolean' }
  testGroupNumber: {type: 'integer', minimum: 0, maximum: 256, exclusiveMaximum: true}
  mailChimp: {type: 'object'}
  hourOfCode: {type: 'boolean'}
  hourOfCodeComplete: {type: 'boolean'}
  lastIP: {type: 'string'}
  createdOnHost: { type: 'string' }

  emailLower: c.shortString()
  nameLower: c.shortString()
  passwordHash: {type: 'string', maxLength: 256}

  # client side
  emailHash: {type: 'string'}

  #Internationalization stuff
  preferredLanguage: {'enum': [null].concat(c.getLanguageCodeArray())}

  signedCLA: c.date({title: 'Date Signed the CLA'})
  wizard: c.object {},
    colorConfig: c.object {additionalProperties: c.colorConfig()}

  aceConfig: c.object { default: { language: 'python', keyBindings: 'default', invisibles: false, indentGuides: false, behaviors: false, liveCompletion: true }},
    language: {type: 'string', 'enum': ['python', 'javascript', 'coffeescript', 'clojure', 'lua', 'java', 'io']}
    keyBindings: {type: 'string', 'enum': ['default', 'vim', 'emacs']}  # Deprecated 2016-05-30; now we just always give them 'default'.
    invisibles: {type: 'boolean' }
    indentGuides: {type: 'boolean' }
    behaviors: {type: 'boolean' }
    liveCompletion: {type: 'boolean' }

  simulatedBy: {type: 'integer', minimum: 0 }
  simulatedFor: {type: 'integer', minimum: 0 }

  # Deprecated. TODO: Figure out how to remove.
  jobProfile: c.object {title: 'Job Profile', default: { active: false, lookingFor: 'Full-time', jobTitle: 'Software Developer', city: 'Defaultsville, CA', country: 'USA', skills: ['javascript'], shortDescription: 'Programmer seeking to build great software.', longDescription: '* I write great code.\n* You need great code?\n* Great!' }},
    lookingFor: {title: 'Looking For', type: 'string', enum: ['Full-time', 'Part-time', 'Remote', 'Contracting', 'Internship'], description: 'What kind of developer position do you want?'}
    jobTitle: {type: 'string', maxLength: 50, title: 'Desired Job Title', description: 'What role are you looking for? Ex.: "Full Stack Engineer", "Front-End Developer", "iOS Developer"' }
    active: {title: 'Open to Offers', type: 'boolean', description: 'Want interview offers right now?'}
    updated: c.date {title: 'Last Updated', description: 'How fresh your profile appears to employers. Profiles go inactive after 4 weeks.'}
    name: c.shortString {title: 'Name', description: 'Name you want employers to see, like "Nick Winter".'}
    city: c.shortString {title: 'City', description: 'City you want to work in (or live in now), like "San Francisco" or "Lubbock, TX".', format: 'city'}
    country: c.shortString {title: 'Country', description: 'Country you want to work in (or live in now), like "USA" or "France".', format: 'country'}
    skills: c.array {title: 'Skills', description: 'Tag relevant developer skills in order of proficiency', maxItems: 30, uniqueItems: true},
      {type: 'string', minLength: 1, maxLength: 50, description: 'Ex.: "objective-c", "mongodb", "rails", "android", "javascript"', format: 'skill'}
    experience: {type: 'integer', title: 'Years of Experience', minimum: 0, description: 'How many years of professional experience (getting paid) developing software do you have?'}
    shortDescription: {type: 'string', maxLength: 140, title: 'Short Description', description: 'Who are you, and what are you looking for? 140 characters max.' }
    longDescription: {type: 'string', maxLength: 600, title: 'Description', description: 'Describe yourself to potential employers. Keep it short and to the point. We recommend outlining the position that would most interest you. Tasteful markdown okay; 600 characters max.', format: 'markdown' }
    visa: visa
    work: c.array {title: 'Work Experience', description: 'List your relevant work experience, most recent first.'},
      c.object {title: 'Job', description: 'Some work experience you had.', required: ['employer', 'role', 'duration']},
        employer: c.shortString {title: 'Employer', description: 'Name of your employer.'}
        role: c.shortString {title: 'Job Title', description: 'What was your job title or role?'}
        duration: c.shortString {title: 'Duration', description: 'When did you hold this gig? Ex.: "Feb 2013 - present".'}
        description: {type: 'string', title: 'Description', description: 'What did you do there? (140 chars; optional)', maxLength: 140}
    education: c.array {title: 'Education', description: 'List your academic ordeals.'},
      c.object {title: 'Ordeal', description: 'Some education that befell you.', required: ['school', 'degree', 'duration']},
        school: c.shortString {title: 'School', description: 'Name of your school.'}
        degree: c.shortString {title: 'Degree', description: 'What was your degree and field of study? Ex. Ph.D. Human-Computer Interaction (incomplete)'}
        duration: c.shortString {title: 'Dates', description: 'When? Ex.: "Aug 2004 - May 2008".'}
        description: {type: 'string', title: 'Description', description: 'Highlight anything about this educational experience. (140 chars; optional)', maxLength: 140}
    projects: c.array {title: 'Projects (Top 3)', description: 'Highlight your projects to amaze employers.', maxItems: 3},
      c.object {title: 'Project', description: 'A project you created.', required: ['name', 'description', 'picture'], default: {name: 'My Project', description: 'A project I worked on.', link: 'http://example.com', picture: ''}},
        name: c.shortString {title: 'Project Name', description: 'What was the project called?' }
        description: {type: 'string', title: 'Description', description: 'Briefly describe the project.', maxLength: 400, format: 'markdown'}
        picture: {type: 'string', title: 'Picture', format: 'image-file', description: 'Upload a 230x115px or larger image showing off the project.'}
        link: c.url {title: 'Link', description: 'Link to the project.'}
    links: c.array {title: 'Personal and Social Links', description: 'Link any other sites or profiles you want to highlight, like your GitHub, your LinkedIn, or your blog.'},
      c.object {title: 'Link', description: 'A link to another site you want to highlight, like your GitHub, your LinkedIn, or your blog.', required: ['name', 'link'], default: {link: 'http://example.com'}},
        name: {type: 'string', maxLength: 30, title: 'Link Name', description: 'What are you linking to? Ex: "Personal Website", "GitHub"', format: 'link-name'}
        link: c.url {title: 'Link', description: 'The URL.' }
    photoURL: {type: 'string', format: 'image-file', title: 'Profile Picture', description: 'Upload a 256x256px or larger image if you want to show a different profile picture to employers than your normal avatar.'}
    curated: c.object {title: 'Curated', required: ['shortDescription', 'mainTag', 'location', 'education', 'workHistory', 'phoneScreenFilter', 'schoolFilter', 'locationFilter', 'roleFilter', 'seniorityFilter']},
      shortDescription:
        title: 'Short description'
        description: 'A sentence or two describing the candidate'
        type: 'string'
      mainTag:
        title: 'Main tag'
        description: 'A main tag to describe this candidate'
        type: 'string'
      location:
        title: 'Location'
        description: 'The CURRENT location of the candidate'
        type: 'string'
      education:
        title: 'Education'
        description: 'The main educational institution of the candidate'
        type: 'string'
      workHistory: c.array {title: 'Work history', description: 'One or two places the candidate has worked', type: 'array'},
        title: 'Workplace'
        type: 'string'
      phoneScreenFilter: phoneScreenFilter
      schoolFilter: schoolFilter
      locationFilter: locationFilter
      roleFilter: roleFilter
      seniorityFilter: seniorityFilter
      featured:
        title: 'Featured'
        type: 'boolean'
        description: 'Should this candidate be prominently featured on the site?'
  jobProfileApproved: {title: 'Job Profile Approved', type: 'boolean', description: 'Whether your profile has been approved by CodeCombat.'}
  jobProfileApprovedDate: c.date {title: 'Approved date', description: 'The date that the candidate was approved'}
  jobProfileNotes: {type: 'string', maxLength: 1000, title: 'Our Notes', description: 'CodeCombat\'s notes on the candidate.', format: 'markdown' }
  employerAt: c.shortString {description: 'If given employer permissions to view job candidates, for which employer?'}
  signedEmployerAgreement: c.object {},
    linkedinID: c.shortString {title: 'LinkedInID', description: 'The user\'s LinkedIn ID when they signed the contract.'}
    date: c.date {title: 'Date signed employer agreement'}
    data: c.object {description: 'Cached LinkedIn data slurped from profile.', additionalProperties: true}
  savedEmployerFilterAlerts: c.array {
    title: 'Saved Employer Filter Alerts'
    description: 'Employers can get emailed alerts whenever there are new candidates matching their filters'
  }, c.object({
    title: 'Saved filter set'
    description: 'A saved filter set'
    required: ['phoneScreenFilter','schoolFilter','locationFilter','roleFilter','seniorityFilter','visa']
  }, {
    phoneScreenFilter:
      title: 'Phone screen filter values'
      type: 'array'
      items:
        type: 'boolean'
    schoolFilter:
      title: 'School filter values'
      type: 'array'
      items:
        type: schoolFilter.type
        enum: schoolFilter.enum
    locationFilter:
      title: 'Location filter values'
      type: 'array'
      items:
        type: locationFilter.type
        enum: locationFilter.enum
    roleFilter:
      title: 'Role filter values'
      type: 'array'
      items:
        type: roleFilter.type
        enum: roleFilter.enum
    seniorityFilter:
      title: 'Seniority filter values'
      type: 'array'
      items:
        type: roleFilter.type
        enum: seniorityFilter.enum
    visa:
      title: 'Visa filter values'
      type: 'array'
      items:
        type: visa.type
        enum: visa.enum
  })

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

  earned: c.RewardSchema 'earned by achievements'
  purchased: c.RewardSchema 'purchased with gems or money'
  deleted: {type: 'boolean'}
  dateDeleted: c.date()
  spent: {type: 'number'}
  stripeCustomerID: { type: 'string' } # TODO: Migrate away from this property

  stripe: c.object {}, {
    customerID: { type: 'string' }
    planID: { enum: ['basic'], description: 'Determines if a user has or wants to subscribe' }
    subscriptionID: { type: 'string', description: 'Determines if a user is subscribed' }
    token: { type: 'string' }
    couponID: { type: 'string' }
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
  country: { type: 'string' }  # Set on new users for certain countries on the server

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
      type: { type: 'string' }
      includedCourseIDs: c.array({ description: 'courseIDs that this prepaid includes access to' }, c.objectId())
    }
  }
  enrollmentRequestSent: { type: 'boolean' }

  schoolName: {type: 'string', description: 'Deprecated string. Use "school" object instead.'}
  role: {type: 'string', enum: ["advisor", "parent", "principal", "student", "superintendent", "teacher", "technology coordinator"]}
  birthday: c.stringDate({title: "Birthday"})
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

c.extendBasicProperties UserSchema, 'user'

UserSchema.definitions =
  emailSubscription: c.object { default:  { enabled: true, count: 0 } }, {
    enabled: {type: 'boolean'}
    lastSent: c.date()
    count: {type: 'integer'}
  }

module.exports = UserSchema
