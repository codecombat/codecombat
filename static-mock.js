const props = {
  permissions: [],
  anonymous: true,
  preferredLanguage: 'en'
};

exports.serverConfig = {
  codeNinja: false,
  static: true
};

exports.features =
  {playViewsOnly: false};

exports.me = {
  showingStaticPagesWhileLoading() { return true; },
  isStudent() { return false; },
  isAnonymous() { return this.get('anonymous'); },
  hasSubscription() { return false; },
  isTeacher() { return false; },
  isHomeUser() { return true; },
  isAdmin() { return false; },
  isSchoolAdmin() { return false; },
  isAPIClient() { return false; },
  isInGodMode() { return false; },
  level() { return 1; },
  useDexecure() { return true; },
  useSocialSignOn() { return true; },
  gems() { return 0; },
  getPhotoURL() { return ''; },
  displayName() { return ''; },
  broadName() { return ''; },
  get(prop) { return props[prop]; },
  freeOnly() { return false; },
  isTarena() { return false; },
  isILK() { return false; },
  isTCode() { return false; },
  useTarenaLogo() { return false; },
  hideTopRightNav() { return false; },
  hideFooter() { return false; },
  useGoogleAnalytics() { return true; },
  showChinaVideo() { return false; },
  showForumLink() { return true; },
  showChinaResourceInfo() { return false; },
  hideDiplomatModal() { return false; },
  showOpenResourceLink() { return true; },
  useStripe() { return true; },
  showChinaHomeVersion() { return false; },
  getHackStackExperimentValue() { return false; }
};

exports.view = {
  isMobile() { return false; },
  isOldBrowser() { return false; },
  isChinaOldBrowser() { return false; },
  isIPadBrowser() { return false; }
};

exports.getQueryVariable = () => null;
