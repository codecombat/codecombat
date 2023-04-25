export default {
  methods: {
    async onChildAccountSubmitHelper (data, { existingAccount = null } = {}) {
      // create parent account
      try {
        if (me.isAnonymous()) {
          me.set('role', 'parent-home')
          await me.save()
          const parent = this.parentAccountData
          await me.signupWithPassword(
            parent.name,
            parent.email,
            parent.password
          )
        }
      } catch (err) {
        console.error('failed to create parent user', err)
        const msg = err?.message || `Parent user: ${err?.responseJSON?.message}` || 'Internal error'
        noty({ text: msg, type: 'error', layout: 'center', timeout: 5000 })
        return
      }

      try {
        if (!existingAccount) {
          await me.createAndAssociateAccount({
            ...data,
            relation: 'children',
            role: 'individual'
          })
        } else {
          const input = { ...existingAccount }
          if (!existingAccount.verify.relation) existingAccount.verify.relation = 'children'
          await me.linkRelatedAccount(input)
        }
      } catch (err) {
        console.error('failed to create/link child user', err)
        const msg = err?.message || `Child user: ${err?.responseJSON?.message}` || 'Internal error'
        noty({ text: msg, type: 'error', layout: 'center', timeout: 5000 })
        return
      }

      window.location = '/parents/dashboard'
    }
  }
}
