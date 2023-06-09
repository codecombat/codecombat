export default {
  methods: {
    async onSwitchUser ({ email, location = null }) {
      await me.spy(email)
      const text = `Switching to ${email} account..`
      const type = 'success'
      noty({ text, type, timeout: 5000, killer: true })
      setTimeout(() => {
        if (location) window.location = location
        else window.location.reload()
      }, 3000)
    }
  }
}
