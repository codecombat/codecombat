const usersApi = require('../core/api').users
const localStorage = require('../core/storage')

function validateEmail(email) {
  const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  return re.test(String(email).toLowerCase());
}

function provisionPremium () {
  usersApi.provisionSubscription({ userId: me.get('_id') })
    .then(({ premiumAdded, isInLibraryNetwork }) => {
      console.log('pro', premiumAdded, isInLibraryNetwork)
      if (premiumAdded) me.fetch({ cache: false })
      if (isInLibraryNetwork) localStorage.save(libraryNetworkLSKey(), true, 24 * 60)
    })
    .catch((err) => {
      console.log('pro err', err)
    })
}

function isInLibraryNetwork () {
  return !!localStorage.load(libraryNetworkLSKey())
}

function libraryNetworkLSKey () {
  return `lib-network-${me.get('_id')}`
}

module.exports = {
  validateEmail,
  provisionPremium,
  isInLibraryNetwork
}
