const usersApi = require('../core/api').users
const localStorage = require('../core/storage')
const globalVar = require('../core/globalVar')

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

async function levelChatCreditsString () {
  const res = await usersApi.getUserCredits('LEVEL_CHAT_BOT')
  const credits = res?.result
  if (!credits || credits.length === 0) {
    return $.i18n.t('user_credits.level_chat_no_credits_left')
  }
  const { creditsLeft, durationKey, durationAmount } = credits[0]
  if (creditsLeft > 0) {
    if (durationAmount > 1) {
      return $.i18n.t('user_credits.level_chat_left_in_duration_multiple', { credits: creditsLeft, duration_key: durationKey, duration_amount: durationAmount })
    } else {
      return $.i18n.t('user_credits.level_chat_left_in_duration', { credits: creditsLeft, duration_key: durationKey })
    }
  } else {
    if (durationAmount > 1) {
      return $.i18n.t('user_credits.level_chat_no_credits_left_duration_multiple', { duration_key: durationKey, duration_amount: durationAmount })
    } else {
      return $.i18n.t('user_credits.level_chat_no_credits_left_duration', { duration_key: durationKey })
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
  updateUserCreditsMessage
}
