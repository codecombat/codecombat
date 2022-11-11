<template>
  <div>
    <div class="library-login">
      <div
        v-if="isArapahoe"
        class="arapahoe common"
      >
        <div class="common__head">
          <img src="/images/pages/play/arapahoe-logo.png" alt="Arapahoe logo" class="common__head-logo">
        </div>
        <form
          v-if="!alreadyLoggedIn"
          @submit.prevent="() => onLibraryLogin({ libraryName: 'arapahoe' })"
        >
          <div class="arapahoe__body">
            <div class="arapahoe__body__library">
              <h2 class="arapahoe__body__library-text">
                {{ $t('library.enter_library_card') }}
              </h2>
              <div class="arapahoe__body__library-input">
                <input type="text" class="form-control arapahoe__body__library-input-box" v-model="libraryProfileId">
              </div>
            </div>
            <div class="arapahoe__body__submit">
              <button type="submit" class="arapahoe__body__submit-btn btn btn-primary">
                {{ $t('library.access_coco') }}
              </button>
            </div>
            <div class="arapahoe__error error" v-if="errMsg">
              {{ errMsg }}
            </div>
          </div>
        </form>
        <div
          v-else
          class="common__already"
        >
          {{ $t('library.already_logged_in') }}
        </div>
      </div>
      <div
        v-else-if="isOpenAthens || isHoustonLibrary"
        class="houston common"
      >
        <div
          v-if="isHoustonLibrary"
          class="common__head"
        >
          <img src="/images/pages/play/houston-library-logo.png" alt="Houston logo" class="common__head-logo">
        </div>
        <div
          v-show="!progressState && !alreadyLoggedIn && showWayFinder"
          id="wayfinder"
        >
          {{ $t('common.loading') }}
        </div>
        <div
          class="houston__login"
          v-if="!alreadyLoggedIn"
        >
          <p
            v-if="!progressState && showWayFinder"
            class="houston__login__option"
          >
            {{ $t('library.search_box_option') }}
            <a
              @click.prevent="redirectToOpenAthens"
              href="#"
              class="houston__login__option-link"
            >
              {{ $t('general.here') }}
            </a>
            {{ $t('code.or') }} <a href="mailto:support@codecombat.com">{{ $t('contact.contact_us') }} </a>
          </p>
          <div
            v-if="!progressState && !showWayFinder"
          >
            <button
              @click="redirectToOpenAthens"
              class="btn btn-primary btn-lg"
            >
              Login / Sign Up
            </button>
          </div>
        </div>
        <div
          v-else
          class="common__already"
        >
          {{ $t('library.already_logged_in') }}
        </div>
        <div
          v-if="progressState"
          class="houston__progress"
        >
          {{ progressState }}
        </div>
        <div
          v-else-if="errMsg"
          class="houston__error error"
        >
          {{ errMsg }}
        </div>
      </div>
      <div class="unknown" v-else>
        {{ $t('not_found.page_not_found') }}
      </div>
    </div>
  </div>
</template>

<script>
import { libraryName } from '../../lib/user-utils'
const usersLib = require('../../core/api/users')
const globalVar = require('core/globalVar')
export default {
  name: 'LibraryLoginView',
  data () {
    return {
      libraryProfileId: null,
      errMsg: null,
      progressState: null,
      alreadyLoggedIn: false
    }
  },
  props: {
    libraryId: {
      type: String,
      required: true
    },
    code: {
      type: String, // houston library response contains code
      default: null
    },
    libName: {
      type: String,
      default: null
    },
    isDeeplink: {
      type: String,
      default: 'false'
    },
    entityID: {
      type: String,
      default: null
    },
    target: {
      type: String,
      default: null
    }
  },
  mounted () {
    this.libraryProfileId = me.get('library')?.profileId
    this.alreadyLoggedIn = !me.isAnonymous()
    if (this.isDeeplink === 'true') {
      // document.cookie = `deeplink=${this.target}; max-age=300; path=/;`
      this.redirectToOpenAthens()
      return
    }
    if (this.isHoustonLibrary || this.isOpenAthens) {
      this.handleHoustonLibrary()
    }
  },
  computed: {
    isHoustonLibrary () {
      return this.isOpenAthens && this.libName === 'houston'
    },
    isOpenAthens () {
      return this.libraryId === 'open-athens' || this.libraryId === 'open-athens-redirect'
    },
    isArapahoe () {
      return this.libraryId === 'arapahoe-13579'
    },
    showWayFinder () {
      return this.libName === 'way-finder'
    }
  },
  methods: {
    async onLibraryLogin ({ libraryName }) {
      this.errMsg = null
      try {
        await usersLib.loginArapahoe({ libraryProfileId: this.libraryProfileId, libraryName })
        await this.postLogin()
      } catch (err) {
        console.error('error resp', err)
        this.errMsg = err.message
        this.progressState = null
      }
    },
    async loginAgain () {
      globalVar.currentView.logoutRedirectURL = null
      await me.logout()
    },
    async postLogin () {
      await me.fetch({ cache: false })
      window.location = '/play'
    },
    async handleHoustonLibrary () {
      if (this.alreadyLoggedIn) {
        return
      }
      this.loadWayFinder()
      if (this.code) {
        this.progressState = 'Fetching user info...'
        this.errMsg = null
        await usersLib.loginHouston({ code: this.code })
        this.progressState = 'Trying to login...'
        await this.postLogin()
        try {
          await usersLib.loginHouston({ code: this.code })
          await this.postLogin()
        } catch (err) {
          console.error('handleOA err', err)
          this.errMsg = err?.message || 'Failed to retrieve user info'
          this.progressState = null
        }
      }
    },
    loadWayFinder () {
      /* eslint-disable */
      (function(w,a,y,f){
          w._wayfinder=w._wayfinder||function(){(w._wayfinder.q=w._wayfinder.q||[]).push(arguments)};
          const p={oaDomain:'codecombat.com',oaAppId:'6a0d8c7e-3577-41e0-9e6b-220da4c8e8c6'};
          w._wayfinder.settings=p;const h=a.getElementsByTagName('head')[0];const s=a.createElement('script');s.async=1;
          const q=Object.keys(p).map(function(key){return key+'='+p[key]}).join('&');
          s.src=y+'v1'+f+"?"+q;h.appendChild(s);}
      )(window,document,'https://wayfinder.openathens.net/embed/','/loader.js');
    },
    redirectToOpenAthens () {
      const clientId = globalVar.application.isProduction() ? 'codecombat.com.oidc-app-v1.705681f4-8cce-48aa-a022-a7a3c65f23c9' : 'codecombat.com.oidc-app-v1.6a0d8c7e-3577-41e0-9e6b-220da4c8e8c6'
      const scope = 'openid'
      const responseType = 'code'
      const redirectId = this.libraryId.includes('-redirect') ? this.libraryId : `${this.libraryId}-redirect`
      const redirectUri = encodeURIComponent(`${window.location.origin}/library/${redirectId}/login`)
      // window.location = `https://connect.openathens.net/codecombat.com/6a0d8c7e-3577-41e0-9e6b-220da4c8e8c6/login?entity=https://idp.bigpharma.com/entity`
      const entityParam = this.entityID ? `&entityID=${encodeURIComponent(this.entityID)}` : ''
      window.location = `https://connect.openathens.net/oidc/auth?client_id=${clientId}&scope=${scope}&response_type=${responseType}&redirect_uri=${redirectUri}${entityParam}`
    }
  }
}
</script>

<style scoped lang="scss">
.library-login {
  font-size: 62.5%;
}
.common {
  text-align: center;
  margin-left: 25%;
  margin-right: 25%;
  padding: 5rem 3rem;

  &__head {
    padding: 1rem;

    &-logo {
      width: 20rem;
    }
  }

  &__already {
    font-size: 1.5rem;
  }
}
.arapahoe {
  background-color: #f4f2f2;

  &__body {

    &__library {
      padding-bottom: 1rem;

      &-text {
        font-weight: 700;
        padding-bottom: .5rem;
      }

      &-input-box {
        width: 70%;
        margin: 0 auto;
      }
    }

    &__submit {
      &-btn {
        padding: 1rem 1.5rem;
      }
    }
  }

  &__msg {
    font-size: 1.8rem;
    padding: 2rem;

    &-text {
      padding-bottom: .5rem;
    }
  }
}

.houston {
  background-color: #f4f2f2;

  &__progress {
    font-size: 1.8rem;
  }

  &__login {
    padding-top: 1rem;

    &__option {
      font-size: 1.5rem;
    }
  }
}

.unknown {
  text-align: center;
  font-size: 2rem;
}

.error {
  color: #ff0000;
  text-align: center;
  font-size: 2rem;
  margin-top: 1rem;
}
</style>
