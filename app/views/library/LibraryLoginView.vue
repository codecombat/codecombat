<template>
  <div>
    <div class="library-login">
      <div class="arapahoe" v-if="libraryId === 'arapahoe-13579'">
        <div class="arapahoe__head">
          <img src="/images/pages/play/arapahoe-logo.png" alt="Arapahoe logo" class="arapahoe__head-logo">
        </div>
        <form @submit.prevent="onArapahoeLogin" v-if="!alreadyHaveProfileId">
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
            <div class="arapahoe__error" v-if="errMsg">
              {{ errMsg }}
            </div>
          </div>
        </form>
        <div class="arapahoe__existing" v-if="alreadyHaveProfileId">
          <div class="arapahoe__existing-text">
            {{ $t('library.already_using_library_id') }} <b>{{ libraryProfileId }}</b>, <a href="/play" class="arapahoe__existing-link">{{ $t('new_home.click_here') }}</a> {{ $t('library.play_coco') }}
          </div>
          <div class="arapahoe__existing__new-text">
            {{ $t('library.not_library_id') }}, <a href="#" class="arapahoe__new_link" @click.prevent="loginAgain">{{ $t('new_home.click_here') }}</a> {{ $t('library.access_using_id') }}
          </div>
        </div>
      </div>
      <div class="unknown" v-else>
        {{ $t('not_found.page_not_found') }}
      </div>
    </div>
  </div>
</template>

<script>
const usersLib = require('../../core/api/users')
const globalVar = require('core/globalVar')
export default {
  name: 'LibraryLoginView',
  data () {
    return {
      libraryProfileId: null,
      errMsg: null,
      alreadyHaveProfileId: false
    }
  },
  props: {
    libraryId: {
      type: String,
      required: true
    }
  },
  created () {
    if (me.get('library')?.profileId) {
      this.libraryProfileId = me.get('library').profileId
    }
    this.alreadyHaveProfileId = me.get('library')?.profileId
  },
  methods: {
    async onArapahoeLogin () {
      this.errMsg = null
      try {
        await usersLib.loginArapahoe({ libraryProfileId: this.libraryProfileId })
        await me.fetch({ cache: false })
        window.location = '/play'
      } catch (err) {
        console.log('error resp', err)
        this.errMsg = err.message
      }
    },
    async loginAgain () {
      globalVar.currentView.logoutRedirectURL = null
      await me.logout()
    }
  }
}
</script>

<style scoped lang="scss">
.library-login {
  font-size: 62.5%;
}
.arapahoe {
  text-align: center;
  background-color: #f4f2f2;
  margin-left: 25%;
  margin-right: 25%;
  padding: 5rem 3rem;

  &__head {
    padding: 1rem;

    &-logo {
      width: 20rem;
    }
  }

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

  &__error {
    color: #ff0000;
    text-align: center;
    font-size: 2rem;
    margin-top: 1rem;
  }

  &__existing {
    font-size: 1.8rem;
    padding: 2rem;

    &-text {
      padding-bottom: .5rem;
    }
  }
}

.unknown {
  text-align: center;
  font-size: 2rem;
}
</style>
