export default {
  methods: {
    onChildPremiumPurchaseClick () {
      if (!this.child) {
        noty({ text: 'No child added', type: 'error', layout: 'center', timeout: 5000 })
        return
      }
      const name = this.child.broadName || ''
      const email = this.child.email || ''
      const msg = `Purchasing for ${name} ${email}`
      noty({ text: msg, type: 'information', layout: 'center', timeout: 5000 })
    }
  }
}
