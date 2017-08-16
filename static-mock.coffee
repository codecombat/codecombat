props = 
  permissions: []
  anonymous: true
  preferredLanguage: 'en'
  
exports.serverConfig =
  codeNinja: false
  static: true

exports.features = 
  playViewsOnly: false

exports.me =
  isStudent: () -> false
  isAnonymous: () -> @get('anonymous')
  hasSubscription: () -> false
  isTeacher: () -> false
  isAdmin: () -> false
  level: () -> 1
  gems: () -> 0
  getPhotoURL: () -> ''
  displayName: () -> ''
  broadName: () -> ''
  get: (prop) -> props[prop]
  isOnPremiumServer: () -> false
  freeOnly: -> false

exports.view = 
  forumLink: () -> 'http://discourse.codecombat.com/'
  isMobile: () -> false
  showAds: () -> false
  isOldBrowser: () -> false
  isIPadBrowser: () -> false
