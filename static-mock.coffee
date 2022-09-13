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
  showingStaticPagesWhileLoading: () -> true
  isStudent: () -> false
  isAnonymous: () -> @get('anonymous')
  hasSubscription: () -> false
  isTeacher: () -> false
  isHomeUser: () -> true
  isAdmin: () -> false
  isSchoolAdmin: () -> false
  isAPIClient: () -> false
  isInGodMode: () -> false
  level: () -> 1
  useDexecure: -> true
  useSocialSignOn: -> true
  gems: () -> 0
  getPhotoURL: () -> ''
  displayName: () -> ''
  broadName: () -> ''
  get: (prop) -> props[prop]
  freeOnly: -> false
  isTarena: -> false
  isILK: -> false
  isTCode: -> false
  useTarenaLogo: -> false
  hideTopRightNav: -> false
  hideFooter: -> false
  useGoogleAnalytics: -> true
  showChinaVideo: -> false
  showForumLink: -> true
  showChinaResourceInfo: -> false
  hideDiplomatModal: -> false
  showOpenResourceLink: -> true
  useStripe: -> true

exports.view =
  forumLink: () -> 'http://discourse.codecombat.com/'
  isMobile: () -> false
  isOldBrowser: () -> false
  isIPadBrowser: () -> false

exports.getQueryVariable = -> null
