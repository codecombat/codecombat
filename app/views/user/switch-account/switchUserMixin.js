export default {
  methods: {
    // identifier: name or email
    async onSwitchUser ({ identifier, location = null }) {
      await me.spy(identifier)
      const text = `Switching to ${identifier} account..`
      const type = 'success'
      noty({ text, type, timeout: 5000, killer: true })
      setTimeout(() => {
        if (location) window.location = location
        else window.location.reload()
      }, 3000)
    }
  }
}
