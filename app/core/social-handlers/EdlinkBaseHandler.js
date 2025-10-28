const CocoClass = require('core/CocoClass')

module.exports = class EdlinkBaseHandler extends CocoClass {
  constructor (providerName) {
    super()
    this.providerName = providerName
  }

  async logInWithEdlink () {
    const state = crypto.getRandomValues(new Uint32Array(1))[0].toString(36)
    const url = `/auth/oauth2/${this.providerName}?state=${state}`
    const popup = window.open(url, '_blank', 'width=800,height=600', false)
    if (!popup) {
      noty({
        text: 'Please allow popups for this site',
        type: 'error',
        timeout: 5000,
        layout: 'topCenter',
      })
      return
    }

    let timeoutId = null
    const connectionTrackingKey = `${this.providerName}ConnectionTrackingKey`

    return new Promise((resolve, reject) => {
      const handleStorageEvent = (event) => {
        if (event.key === connectionTrackingKey) {
          const result = localStorage.getItem(connectionTrackingKey)
          const parsedResult = JSON.parse(result)
          if (parsedResult.state === state) {
            localStorage.removeItem(connectionTrackingKey)
            window.removeEventListener('storage', handleStorageEvent)
            if (timeoutId) clearTimeout(timeoutId)
            const { state, ...rest } = parsedResult
            resolve(rest)
          } else {
            window.removeEventListener('storage', handleStorageEvent)
            if (timeoutId) clearTimeout(timeoutId)
            reject(new Error(`State mismatch: ${parsedResult.state} !== ${state}`))
          }
        }
      }

      try {
        window.addEventListener('storage', handleStorageEvent)
        // Add timeout to prevent hanging promises
        timeoutId = setTimeout(() => {
          window.removeEventListener('storage', handleStorageEvent)
          noty({
            text: 'Login timeout',
            type: 'error',
            timeout: 5000,
            layout: 'topCenter',
          })
          reject(new Error('Login timeout'))
        }, 90000)
      } catch (error) {
        reject(error)
      }
    })
  }

  async connect (options) {
    this.trigger('connect')
    const result = await this.logInWithEdlink()

    if (result.loggedIn) {
      // login user if already signed up
      window.location.reload()
      return
    }

    if (!result.email) {
      throw new Error(`No email found in ${this.providerName} response`)
    }

    this.trigger('connect')
    this.result = result
    return options.success.bind(options.context)(result)
  }

  loadPerson (options) {
    this.trigger('load-person', options)
    return options.success.bind(options.context)(this.result)
  }
}