import BaseTracker from './BaseTracker'

const makelogOrgId = 'org-2F8P67Q21Vm51O97wEnzbtwrg9W'

export default class MakelogTracker extends BaseTracker {
  constructor (store) {
    super()
    this.store = store
  }

  async _initializeTracker () {
    const script = document.createElement('script')
    script.src = 'https://unpkg.com/@mklog/widgets@latest'
    script.async = true
    script.type = 'module'
    document.head.appendChild(script);

    // We don't need to create the widget here; we'Ll create it wherever we want it to live (footer, etc.)

    this.enabled = true
    this.onInitializeSuccess()
  }
}
