const usersApi = require('../core/api').users
const localStorage = require('../core/storage')
const globalVar = require('../core/globalVar')
const _ = require('lodash')

function extraProvisions () {
  usersApi.extraProvisions({ userId: me.get('_id') })
    .then(({ provisionType, ...obj }) => {
      if (provisionType === 'library') {
        const { premiumAdded, isInLibraryNetwork, hideEmail, libraryName, showLoginModal, isCreatedViaLibrary } = obj
        handleStorage(libraryNetworkLSKey(), isInLibraryNetwork, 24 * 60)
        handleStorage(hideEmailLibraryKey(), hideEmail, 24 * 60)
        handleStorage(showLibraryLoginModalKey(), showLoginModal, 60)
        handleStorage(isCreatedViaLibraryKey(), isCreatedViaLibrary, 24 * 60)
        handleStorage(libraryNameKey(), libraryName, 24 * 60)

        const lib = me.get('library') || {}
        if (!lib.name && libraryName) {
          lib.name = libraryName
          me.set('library', lib)
          me.save()
        }
        if (premiumAdded) me.fetch({ cache: false })
      } else if (provisionType === 'teacher') {
        const { esportsAdded } = obj
        if (esportsAdded) me.fetch({ cache: false })
      }
    })
    .catch((err) => {
      console.error('provision err', err)
    })
}

function handleStorage (key, value, expirationInMinutes) {
  if (value) {
    localStorage.save(key, value, expirationInMinutes)
  } else {
    localStorage.remove(key)
  }
}

function isInLibraryNetwork () {
  return !!localStorage.load(libraryNetworkLSKey())
}

function libraryNetworkLSKey () {
  return `lib-network-${me.get('_id')}`
}

function shouldHideEmail () {
  return !!localStorage.load(hideEmailLibraryKey())
}

function shouldShowLibraryLoginModal () {
  return !!localStorage.load(showLibraryLoginModalKey())
}

function hideEmailLibraryKey () {
  return `hide-email-library-${me.get('_id')}`
}

function libraryName () {
  return localStorage.load(libraryNameKey())
}

function libraryNameKey () {
  return `library-name-${me.get('_id')}`
}

function showLibraryLoginModalKey () {
  return `library-modal-${me.get('_id')}`
}

function isCreatedViaLibraryKey () {
  return `is-created-via-library-${me.get('_id')}`
}

function isCreatedViaLibrary () {
  return localStorage.load(isCreatedViaLibraryKey())
}

function removeLibraryKeys () {
  localStorage.remove(hideEmailLibraryKey())
  localStorage.remove(libraryNameKey())
  localStorage.remove(libraryNetworkLSKey())
  localStorage.remove(isCreatedViaLibraryKey())
}

function getActivityStatusCacheKey (userId) {
  return `coco-activity-status-${userId}`
}

function readActivityStatusCache (userId) {
  const key = getActivityStatusCacheKey(userId)
  return localStorage.load(key, false) || localStorage.load(key) || {}
}

function activityFromRemote (remoteActivity) {
  if (!remoteActivity?.first) { return null }
  return {
    first: new Date(remoteActivity.first).getTime(),
    last: remoteActivity.last ? new Date(remoteActivity.last).getTime() : undefined,
    count: remoteActivity.count,
  }
}

function normalizeCacheEntry (value) {
  if (value == null) { return null }
  if (typeof value === 'number') {
    return { first: value, last: value, count: 1 }
  }
  if (value.first == null) { return null }
  return {
    first: typeof value.first === 'number' ? value.first : new Date(value.first).getTime(),
    last: value.last != null ? (typeof value.last === 'number' ? value.last : new Date(value.last).getTime()) : undefined,
    count: value.count,
  }
}

function readActivityFromCache (userId, activityName) {
  return normalizeCacheEntry(readActivityStatusCache(userId)[activityName])
}

function reconcileActivity (localActivity, remoteActivity) {
  const remote = activityFromRemote(remoteActivity)
  if (!localActivity) { return remote }
  if (!remote) { return localActivity }
  if ((remote.count ?? 0) > (localActivity.count ?? 0)) { return remote }
  if ((remote.count ?? 0) < (localActivity.count ?? 0)) { return localActivity }
  if ((remote.last ?? 0) > (localActivity.last ?? 0)) { return remote }
  return localActivity
}

function writeActivityToCache (userId, activityName, activity) {
  const key = getActivityStatusCacheKey(userId)
  const cache = readActivityStatusCache(userId)
  cache[activityName] = activity
  localStorage.save(key, cache, 0)
}

function clearActivityStatusCache (userId, { prefix } = {}) {
  const key = getActivityStatusCacheKey(userId)
  if (!prefix) {
    localStorage.remove(key, false)
    localStorage.remove(key)
    return
  }
  const cache = readActivityStatusCache(userId)
  const filtered = _.pick(cache, _.filter(_.keys(cache), k => !k.startsWith(prefix)))
  if (_.isEmpty(filtered)) {
    localStorage.remove(key, false)
    localStorage.remove(key)
  } else {
    localStorage.save(key, filtered, 0)
  }
}

async function levelChatCreditsString () {
  const res = await usersApi.getUserCredits('LEVEL_CHAT_BOT')
  const credits = res?.result
  if (!credits || credits.length === 0) {
    return $.i18n.t('user_credits.level_chat_no_credits_left')
  }
  const { creditsLeft, durationKey, durationAmount } = credits[0]
  const i18nKey = $.i18n.t(`user_credits.level_chat_duration_${durationKey}`)
  if (creditsLeft > 0) {
    if (durationAmount > 1) {
      return $.i18n.t('user_credits.level_chat_left_in_duration_multiple', { credits: creditsLeft, duration_key: i18nKey, duration_amount: durationAmount })
    } else {
      return $.i18n.t('user_credits.level_chat_left_in_duration', { credits: creditsLeft, duration_key: i18nKey })
    }
  } else {
    if (durationAmount > 1) {
      return $.i18n.t('user_credits.level_chat_no_credits_left_duration_multiple', { duration_key: i18nKey, duration_amount: durationAmount })
    } else {
      return $.i18n.t('user_credits.level_chat_no_credits_left_duration', { duration_key: i18nKey })
    }
  }
}

function updateUserCreditsMessage () {
  if (globalVar.fetchingCreditsString) return

  globalVar.fetchingCreditsString = true
  levelChatCreditsString().then(msg => {
    if (msg !== globalVar.userCreditsMessage) {
      globalVar.userCreditsMessage = msg
      Backbone.Mediator.publish('auth:user-credits-message-updates', {})
    }
    globalVar.fetchingCreditsString = false
  })
}
function hasSeenParentBuyingforSelfPrompt () {
  return !!localStorage.load(parentBuyingforSelfPromptKey())
}

function parentBuyingforSelfPromptKey () {
  return `parent-buying-for-self-prompt-${me.get('_id')}`
}

function markParentBuyingForSelfPromptSeen () {
  localStorage.save(parentBuyingforSelfPromptKey(), true, 24 * 60)
}

function getStorageExam () {
  const me = window.me
  return localStorage.load(`exam-${me.id}`, true)
}

function levelsOfExam (exam) {
  if (!exam) { return [] }
  const levels = []
  exam.problems.forEach((course) => {
    const courseId = course.courseId
    course.levels.forEach(level => {
      levels.push({
        ...level,
        courseId,
      })
    })
  })
  return levels
}

function levelNumberInExam (slug) {
  const exam = getStorageExam()
  if (!exam) {
    return 0
  }
  const levels = levelsOfExam(exam)
  return _.findIndex(levels, { slug }) + 1
}

module.exports = {
  extraProvisions,
  isInLibraryNetwork,
  shouldHideEmail,
  libraryName,
  removeLibraryKeys,
  shouldShowLibraryLoginModal,
  levelChatCreditsString,
  isCreatedViaLibrary,
  hasSeenParentBuyingforSelfPrompt,
  markParentBuyingForSelfPromptSeen,
  updateUserCreditsMessage,
  getStorageExam,
  levelsOfExam,
  levelNumberInExam,
  getActivityStatusCacheKey,
  readActivityFromCache,
  reconcileActivity,
  writeActivityToCache,
  activityFromRemote,
  clearActivityStatusCache,
}
