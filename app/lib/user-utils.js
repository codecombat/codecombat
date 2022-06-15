const usersApi = require('../core/api').users
const localStorage = require('../core/storage')

function provisionPremium () {
  usersApi.provisionSubscription({ userId: me.get('_id') })
      .then(({ premiumAdded, isInLibraryNetwork, hideEmail, libraryName }) => {
        if (premiumAdded) me.fetch({ cache: false })
        if (isInLibraryNetwork) localStorage.save(libraryNetworkLSKey(), true, 24 * 60)
        if (hideEmail) localStorage.save(hideEmailLibraryKey(), true, 24 * 60)
        if (libraryName) localStorage.save(libraryNameKey(), libraryName, 24 * 60)
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

function hideEmailLibraryKey () {
  return `hide-email-library-${me.get('_id')}`
}

function libraryName () {
  return localStorage.load(libraryNameKey())
}

function libraryNameKey () {
  return `library-name-${me.get('_id')}`
}

module.exports = {
  provisionPremium,
  isInLibraryNetwork,
  shouldHideEmail,
  libraryName
}
