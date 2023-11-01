export default {
  methods: {
    onChildPremiumPurchaseClick () {
      if (!this.child) {
        noty({ text: 'No child added', type: 'error', layout: 'center', timeout: 5000 })
        return
      }
      const msg = `Purchasing for ${this.child.broadName} - ${this.child.email}`
      noty({ text: msg, type: 'information', layout: 'center', timeout: 5000 })
    }
  }
}
