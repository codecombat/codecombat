import BaseTracker from './BaseTracker'

const makelogOrgId = 'org-2F8P67Q21Vm51O97wEnzbtwrg9W'

export default class MakelogTracker extends BaseTracker {
  constructor (store) {
    super()
    this.store = store
  }

  async _initializeTracker () {
    //if (this.store.state.me.isAdmin) {  // Why doesn't this work? this.store.state.me.isAdmin is undefined
    if (me.isAdmin()) {
      const script = document.createElement('script')
      script.src = 'https://unpkg.com/@mklog/widgets@latest'
      script.async = true
      script.type = 'module'
      document.head.appendChild(script);

      // We don't need to create the widget here; we'Ll create it wherever we want it to live (footer, etc.)
      // TODO: unhide those mklog-ledger and mk-since-last-viewed elements with CSS if we are actually going to show them
      //const widget = document.createElement('mklog-ledger')
      //widget.setAttribute('organization', makelogOrgId)
      //widget.setAttribute('kind', 'popper')
      //document.body.appendChild(widget)

      this.enabled = true
    }

    this.onInitializeSuccess()
  }
}
