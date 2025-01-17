const CocoClass = require('core/CocoClass')

const PROVIDER_NAME = 'schoology'

module.exports = class SchoologyHandler extends CocoClass {
  static async logInWithSchoology () {
    const state = Math.random().toString(36).substring(2)
    const url = `/auth/oauth2/${PROVIDER_NAME}?state=${state}`

    window.open(url, '_blank', 'width=800,height=600', false)

    const connectionTrackingKey = `${PROVIDER_NAME}ConnectionTrackingKey`

    return new Promise((resolve, reject) => {
      const handleStorageEvent = (event) => {
        if (event.key === connectionTrackingKey) {
          const result = localStorage.getItem(connectionTrackingKey)
          const parsedResult = JSON.parse(result)
          if (parsedResult.state === state) {
            localStorage.removeItem(connectionTrackingKey)
            window.removeEventListener('storage', handleStorageEvent)
            const { state, ...rest } = parsedResult
            resolve(rest)
          } else {
            reject(new Error(`State mismatch: ${parsedResult.state} !== ${state}`))
          }
        }
      }

      try {
        window.addEventListener('storage', handleStorageEvent)
      } catch (error) {
        reject(error)
      }
    })
  }

  async connect (options) {
    this.trigger('connect')
    const result = await SchoologyHandler.logInWithSchoology()

    if (result.loggedIn) {
      // login user if already signed up with Schoology
      window.location.reload()
      return
    }

    if (!result.email) {
      throw new Error('No email found in Schoology response')
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