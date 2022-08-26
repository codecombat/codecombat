<template>
  <div class="related">
    <div class="related__heading">
      <h3 class="related__heading__text">
        {{ $t('related_accounts.related_users') }}:
      </h3>
      <p class="related__heading__subtext">
        {{ $t('related_accounts.subtitle') }}
      </p>
    </div>
    <div
      v-if="!related || related.length === 0"
      class="related__none"
    >
      <p class="related__none__text">
        {{ $t('related_accounts.no_related_users') }}
      </p>
    </div>
    <div
      v-if="related && related.length"
      class="related__main"
    >
      <div
        v-for="user in related"
        :key="user.userId"
        class="related__main__user"
      >
        <div class="row related__user">
          <div class="col-md-7">
            <div class="related__user__text">
              {{ user.email }} <span class="related__user__text-help">{{ relatedUserInfo(user) }}</span>
            </div>
          </div>
          <div
            class="col-md-3"
          >
            <div
              v-if="!user.verified"
              class="related__user__not__verified"
            >
              <button
                class="btn btn-warning"
                :disabled="confirmEmailSentFor === user.email"
                @click="() => onSendVerifyEmail({ userId: user.userId, email: user.email })"
              >
                {{ confirmEmailSentFor === user.email ? $t('common.sent') : $t('related_accounts.send_verify_email') }}
              </button>
            </div>
            <div
              v-else
              class="related__user__verified"
            >
              {{ $t('related_accounts.verified') }}
            </div>
          </div>
          <div class="col-md-2">
            <div class="related__user__switch">
              <button
                class="btn btn-success"
                :disabled="!user.verified || isInSwitchedAccount()"
                @click="() => onSwitch({ email: user.email })"
              >
                {{ $t('related_accounts.switch') }}
              </button>
              <span
                class="related__user__switch__close"
                @click="() => onRemoveUser({ userId: user.userId })"
              >
                <icon-close-red />
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import IconCloseRed from '../../../core/components/IconCloseRed'
export default {
  name: 'RelatedUserComponent',
  components: {
    IconCloseRed
  },
  props: {
    related: {
      type: Array,
      default: null
    },
    confirmEmailSentFor: {
      type: String,
      default: ''
    }
  },
  methods: {
    onSwitch ({ email }) {
      this.$emit('switchUser', { email })
    },
    onRemoveUser ({ userId }) {
      this.$emit('removeUser', { userId })
    },
    onSendVerifyEmail ({ userId, email }) {
      this.$emit('sendVerifyEmail', { userId, email })
    },
    relatedUserInfo (user) {
      const info = []
      if (user.broadName) {
        info.push(user.broadName)
      }
      if (user.role) {
        info.push(user.role)
      } else {
        info.push('Individual')
      }
      if (info.length === 0) return ''
      return `( ${info.join(' - ')} )`
    },
    isInSwitchedAccount () {
      return window.serverSession && window.serverSession.amActually
    }
  }
}
</script>

<style scoped lang="scss">
.related {
  &__none {
    &__text {
      font-size: 1.8rem;
    }
  }

  &__heading {
    &__subtext {
      color: #838383;
      font-size: 1.4rem;
      line-height: 2.5rem;
    }
  }

  &__user {
    margin-bottom: 1rem;
    background-color: #f0f8ff;
    padding: 1rem;
    border-radius: 5px;

    &__verified {
      text-align: center;
      color: #73A839;
      font-size: 1.5rem;
    }
    &__not__verified {
      display: inline-block;
    }
    &__switch {
      display: inline-block;

      &__close {
        margin-left: 1rem;
      }
    }
    &__text {
      font-size: 1.6rem;

      &-help {
        font-size: 1.4rem;
        color: #838383;
      }
    }
  }
}
</style>
