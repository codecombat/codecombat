const usersApi = require('../core/api').users
const localStorage = require('../core/storage')

function provisionPremium () {
  usersApi.provisionSubscription({ userId: me.get('_id') })
    .then(({ premiumAdded, isInLibraryNetwork, hideEmail, libraryName, showLoginModal }) => {
      if (isInLibraryNetwork) localStorage.save(libraryNetworkLSKey(), true, 24 * 60)
      if (hideEmail) localStorage.save(hideEmailLibraryKey(), true, 24 * 60)
      if (libraryName) localStorage.save(libraryNameKey(), libraryName, 24 * 60)
      if (showLoginModal) localStorage.save(showLibraryLoginModalKey(), true, 60)
      const lib = me.get('library') || {}
      if (!lib.name && libraryName) {
        lib.name = libraryName
        me.set('library', lib)
        me.save()
      }
      if (premiumAdded) me.fetch({ cache: false })
    })
    .catch((err) => {
      console.error('provision err', err)
    })
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

function removeLibraryKeys () {
  localStorage.remove(hideEmailLibraryKey())
  localStorage.remove(libraryNameKey())
  localStorage.remove(libraryNetworkLSKey())
}

module.exports = {
  provisionPremium,
  isInLibraryNetwork,
  shouldHideEmail,
  libraryName,
  removeLibraryKeys,
  shouldShowLibraryLoginModal
}
