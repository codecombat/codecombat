const CocoClass = require('core/CocoClass')
const { me } = require('core/auth')

const userPropsToSave = {
  first_name: 'firstName',
  last_name: 'lastName',
  gender: 'gender',
  email: 'email',
  id: 'facebookID'
}

class FacebookHandler extends CocoClass {
  constructor () {
    super()
    if (!me.useSocialSignOn()) {
      throw new Error('Social single sign on not supported')
    }
    this.startedLoading = false
    this.apiLoaded = false
    this.connected = false
    this.person = null
  }

  token () {
    return this.authResponse ? this.authResponse.accessToken : undefined
  }

  fakeAPI () {
    window.FB = {
      login (cb) {
        return cb({
          status: 'connected',
          authResponse: {
            accessToken: '1234'
          }
        })
      },
      api (url, options, cb) {
        return cb({
          first_name: 'Mr',
          last_name: 'Bean',
          id: 'abcd',
          email: 'some@email.com'
        })
      }
    }

    this.startedLoading = true
    this.apiLoaded = true
  }

  // Other methods...

  loadPerson (options = {}) {
    options.success = options.success || (() => {})
    options.context = options.context || options
    FB.api('/me', {
      fields: 'email,last_name,first_name,gender'
    }, (person) => {
      const attrs = {}
      for (const fbProp in userPropsToSave) {
        const userProp = userPropsToSave[fbProp]
        const value = person[fbProp]
        if (value) {
          attrs[userProp] = value
        }
      }
      this.trigger('load-person', attrs)
      return options.success.bind(options.context)(attrs)
    })
  }

  renderButtons () {
    if (FB?.XFBML?.parse) {
      setTimeout(FB.XFBML.parse, 10)
    }
  }
}

module.exports = FacebookHandler
