import VueComponentView from './VueComponentView'

import store from 'core/store'
import cocoVueRouter from 'app/core/vueRouter'

import Root from '../../components/Root'

const utils = require('core/utils')
const storage = require('core/storage')


export default class SingletonAppVueComponentView extends VueComponentView {

  constructor () {
    // For now we only support the default the default base-flat template
    super(null, {})

    // Head tag management will be performed inside of Vue app
    this.skipMetaBinding = true
  }


  afterRender () {
    this.setupHashHandlers()
    return super.afterRender()
  }  

  setupHashHandlers(){
    let modalOpened = false
    if (me.isAnonymous()) {
      const hash = document.location.hash;
      const registering = utils.getQueryVariable('registering');
      const createAccount = utils.getQueryVariable('create-account');
    
      const paths = {
        '#create-account': null,
        '#create-account-individual': 'individual',
        '#create-account-home': 'individual-basic',
        '#create-account-student': 'student',
        '#create-account-teacher': 'teacher'
      };
    
      if ((hash === '#create-account' && registering === true) || paths[hash] || createAccount === 'teacher') {
        const startOnPath = paths[hash] || createAccount;
        _.defer(() => { 
          if (!this.destroyed) { 
            return this.openCreateAccountModal({ startOnPath })
          } 
        });
        modalOpened = true;
      }
    
      if (hash === '#login') {
        const url = new URLSearchParams(window.location.search);
        _.defer(() => { 
          if (!this.destroyed) { 
            return this.openAuthModal({ initialValues: { email: url.get('email') } }) 
          } 
        });
        modalOpened = true;
      }
    }

    // only open modal if no other modal is open
    if(!modalOpened && !this.destroyed){
      _.defer(() => {
        const MineModal = require('views/core/MineModal') // Roblox modal
        if (!storage.load('roblox-clicked') && !this.destroyed) { return this.openModalView(new MineModal()) } 
      })
    }
  }

  buildVueComponent () {
    this.router = cocoVueRouter()

    this.router.afterEach((to, from) => {
      // Fixes issue of page not scrolling to top on navigation change
      if (to.path !== from.path) {
        // If the user has navigated within the router, try and reset the scroll position.
        try {
          // Required so that jade recompiles with new variables.
          this.render()
          window.scrollTo(0, 0)
        } catch (e) {
          // Can fail silently. Handling browser compatibility
        }
      }
    })

    return new Vue({
      el: this.$el.find('#site-content-area')[0],

      store,
      router: this.router,

      render: (h) => h(Root),

      provide: {
        openLegacyModal: this.openModalView.bind(this),
        legacyModalClosed: this.modalClosed.bind(this)
      }
    })
  }
}
