c = require './../schemas'
emailSubscriptions = ['announcement', 'tester', 'level_creator', 'developer', 'article_editor', 'translator', 'support', 'notification']

UserSchema = c.object
  title: 'User'

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
  default: 'Authorized to work in the US'
  
_.extend UserSchema.properties,
  email: c.shortString({title: 'Email', format: 'email'})
  firstName: c.shortString({title: 'First Name'})
  lastName: c.shortString({title: 'Last Name'})
  gender: {type: 'string', 'enum': ['male', 'female']}
  password: {type: 'string', maxLength: 256, minLength: 2, title: 'Password'}
  passwordReset: {type: 'string'}
  photoURL: {type: 'string', format: 'image-file', title: 'Profile Picture', description: 'Upload a 256x256px or larger image to serve as your profile picture.'}

  facebookID: c.shortString({title: 'Facebook ID'})
  gplusID: c.shortString({title: 'G+ ID'})

  wizardColor1: c.pct({title: 'Wizard Clothes Color'})
  volume: c.pct({title: 'Volume'})
  music: {type: 'boolean', default: true}
  autocastDelay: {type: 'integer', 'default': 5000}
  lastLevel: {type: 'string'}

  emailSubscriptions: c.array {uniqueItems: true}, {'enum': emailSubscriptions}
  emails: c.object {title: 'Email Settings', default: {generalNews: {enabled: true}, anyNotes: {enabled: true}, recruitNotes: {enabled: true}}},
    # newsletters
    generalNews: {$ref: '#/definitions/emailSubscription'}
    adventurerNews: {$ref: '#/definitions/emailSubscription'}
    ambassadorNews: {$ref: '#/definitions/emailSubscription'}
    archmageNews: {$ref: '#/definitions/emailSubscription'}
    artisanNews: {$ref: '#/definitions/emailSubscription'}
    diplomatNews: {$ref: '#/definitions/emailSubscription'}
    scribeNews: {$ref: '#/definitions/emailSubscription'}

    # notifications
    anyNotes: {$ref: '#/definitions/emailSubscription'} # overrides any other notifications settings
    recruitNotes: {$ref: '#/definitions/emailSubscription'}
    employerNotes: {$ref: '#/definitions/emailSubscription'}

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
  emailHash: {type: 'string'}

  #Internationalization stuff
  preferredLanguage: {type: 'string', default: 'en', 'enum': c.getLanguageCodeArray()}

  signedCLA: c.date({title: 'Date Signed the CLA'})
  wizard: c.object {},
    colorConfig: c.object {additionalProperties: c.colorConfig()}

  aceConfig: c.object {},
    language: {type: 'string', 'default': 'javascript', 'enum': ['javascript', 'coffeescript', 'python', 'clojure', 'lua', 'io']}
    keyBindings: {type: 'string', 'default': 'default', 'enum': ['default', 'vim', 'emacs']}
    invisibles: {type: 'boolean', 'default': false}
    indentGuides: {type: 'boolean', 'default': false}
    behaviors: {type: 'boolean', 'default': false}
    liveCompletion: {type: 'boolean', 'default': true}

  simulatedBy: {type: 'integer', minimum: 0, default: 0}
  simulatedFor: {type: 'integer', minimum: 0, default: 0}

  jobProfile: c.object {title: 'Job Profile', required: ['lookingFor', 'jobTitle', 'active', 'name', 'city', 'country', 'skills', 'experience', 'shortDescription', 'longDescription', 'visa', 'work', 'education', 'projects', 'links']},
    lookingFor: {title: 'Looking For', type: 'string', enum: ['Full-time', 'Part-time', 'Remote', 'Contracting', 'Internship'], default: 'Full-time', description: 'What kind of developer position do you want?'}
    jobTitle: {type: 'string', maxLength: 50, title: 'Desired Job Title', description: 'What role are you looking for? Ex.: "Full Stack Engineer", "Front-End Developer", "iOS Developer"', default: 'Software Developer'}
    active: {title: 'Open to Offers', type: 'boolean', description: 'Want interview offers right now?'}
    updated: c.date {title: 'Last Updated', description: 'How fresh your profile appears to employers. Profiles go inactive after 4 weeks.'}
    name: c.shortString {title: 'Name', description: 'Name you want employers to see, like "Nick Winter".'}
    city: c.shortString {title: 'City', description: 'City you want to work in (or live in now), like "San Francisco" or "Lubbock, TX".', default: 'Defaultsville, CA', format: 'city'}
    country: c.shortString {title: 'Country', description: 'Country you want to work in (or live in now), like "USA" or "France".', default: 'USA', format: 'country'}
    skills: c.array {title: 'Skills', description: 'Tag relevant developer skills in order of proficiency.', default: ['javascript'], minItems: 1, maxItems: 30, uniqueItems: true},
      {type: 'string', minLength: 1, maxLength: 50, description: 'Ex.: "objective-c", "mongodb", "rails", "android", "javascript"', format: 'skill'}
    experience: {type: 'integer', title: 'Years of Experience', minimum: 0, description: 'How many years of professional experience (getting paid) developing software do you have?'}
    shortDescription: {type: 'string', maxLength: 140, title: 'Short Description', description: 'Who are you, and what are you looking for? 140 characters max.', default: 'Programmer seeking to build great software.'}
    longDescription: {type: 'string', maxLength: 600, title: 'Description', description: 'Describe yourself to potential employers. Keep it short and to the point. We recommend outlining the position that would most interest you. Tasteful markdown okay; 600 characters max.', format: 'markdown', default: '* I write great code.\n* You need great code?\n* Great!'}
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
        name: c.shortString {title: 'Project Name', description: 'What was the project called?', default: 'My Project'}
        description: {type: 'string', title: 'Description', description: 'Briefly describe the project.', maxLength: 400, default: 'A project I worked on.', format: 'markdown'}
        picture: {type: 'string', title: 'Picture', format: 'image-file', description: 'Upload a 230x115px or larger image showing off the project.'}
        link: c.url {title: 'Link', description: 'Link to the project.', default: 'http://example.com'}
    links: c.array {title: 'Personal and Social Links', description: 'Link any other sites or profiles you want to highlight, like your GitHub, your LinkedIn, or your blog.'},
      c.object {title: 'Link', description: 'A link to another site you want to highlight, like your GitHub, your LinkedIn, or your blog.', required: ['name', 'link']},
        name: {type: 'string', maxLength: 30, title: 'Link Name', description: 'What are you linking to? Ex: "Personal Website", "GitHub"', format: 'link-name'}
        link: c.url {title: 'Link', description: 'The URL.', default: 'http://example.com'}
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
  jobProfileNotes: {type: 'string', maxLength: 1000, title: 'Our Notes', description: 'CodeCombat\'s notes on the candidate.', format: 'markdown', default: ''}
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


c.extendBasicProperties UserSchema, 'user'

c.definitions =
  emailSubscription =
    enabled: {type: 'boolean'}
    lastSent: c.date()
    count: {type: 'integer'}

module.exports = UserSchema
