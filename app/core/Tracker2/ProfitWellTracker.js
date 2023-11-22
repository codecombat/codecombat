import BaseTracker from './BaseTracker'

export function loadProfitWell () {
  /* eslint-disable */
  const token = '89ed4df33a1bbc8816793a66941361ed'
  const script = document.createElement('script')
  script.id = 'profitwell-js'
  script.setAttribute('data-pw-auth', token)
  script.text = "(function(i,s,o,g,r,a,m){i[o]=i[o]||function(){(i[o].q=i[o].q||[]).push(arguments)}; a=s.createElement(g);m=s.getElementsByTagName(g)[0];a.async=1;a.src=r+'?auth='+ s.getElementById(o+'-js').getAttribute('data-pw-auth');m.parentNode.insertBefore(a,m); })(window,document,'profitwell','script','https://public.profitwell.com/js/profitwell.js');"
  const firstScript = document.getElementsByTagName("script")[0];
  firstScript.parentNode.insertBefore(script, firstScript);
}

export default class ProfitWellTracker extends BaseTracker {
  constructor (store) {
    super()
    this.store = store
  }

  async _initializeTracker () {
    try {
      loadProfitWell()
    } catch (error) {
      this.log(error)
      this.onInitializeFail(error)
      return
    }

    const { me } = this.store.state
    const options = {}
    if (me.email) {
      options.user_email = me.email
    } else if (me.stripe && me.stripe.customerID) {
      options.user_id = me.stripe.customerID
    }

    this.log('starting profitwell with options', options)
    profitwell('start', options)
    this.onInitializeSuccess()
  }
}
