<template>
  <PageSection class="section">
    <template #heading>
      {{ $t('roblox.link_reward') }}
    </template>
    <template #body>
      <ProgressBar
        :progress="progress"
        :dots="3"
        class="roblox-progress-bar"
      >
        <template
          v-for="(label, index) in labels"
          #[`dot-label-${index}`]
        >
          <div
            :key="`label-${index}`"
            class="progress-labels"
          >
            <img
              :src="label.img"
              class="icon"
            >
            <p>
              {{ label.text }}
            </p>
            <p>
              {{ $t('roblox_landing.connect_button_accounts_linked') }}
            </p>
          </div>
        </template>
      </ProgressBar>
    </template>
    <template #tail>
      <div class="tail">
        <p>
          {{ $t('roblox.link_reward_desc') }}
        </p>
        <div class="points">
          <img
            class="roblox-logo"
            :src="robloxLogo"
          >
          <ul>
            <li
              v-for="(item, i) in connectListsOne"
              :key="`list-1-${i}`"
            >
              {{ item.text }}
            </li>
          </ul>
          <ul>
            <li
              v-for="(item, i) in connectListsTwo"
              :key="`list-2-${i}`"
            >
              {{ item.text }}
            </li>
          </ul>
        </div>
        <p class="content">
          {{ $t('roblox.link_encouragement') }}
        </p>
        <div
          v-if="isConnected"
          class="identities"
        >
          <div
            v-for="identity in robloxIdentities"
            :key="identity.sub"
            class="identity"
          >
            <!-- eslint-disable vue/no-v-html -->
            <p
              v-html="$t('account_settings.roblox_connected', { username: identity.get('profile').preferred_username })"
            />
            <!--eslint-enable-->
            <CTAButton
              @clickedCTA="disconnectFromRoblox(identity)"
            >
              {{ $t('account_settings.disconnect_roblox_button') }}
            </CTAButton>
          </div>
        </div>
        <div v-else>
          <CTAButton
            v-if="me.canUseRobloxOauthConnection()"
            :class="{ 'login-button': isAnonymous }"
            :data-login-message="$t('roblox_landing.login_message')"
            :data-next-url="nextURL"
            @clickedCTA="connectToRoblox"
          >
            {{ $t('roblox.link_now') }}
          </CTAButton>
          <div
            v-if="me.canUseRobloxOauthConnection()"
            class="age-restriciton-warning"
          >
            {{ $t('roblox_landing.age_restriction') }}
          </div>
          <RobloxIdentityField
            v-if="!me.canUseRobloxOauthConnection()"
            :user-id="me.id"
            @saved="checkRobloxConnectionStatus"
          />
        </div>
      </div>
      <vue-confirm-dialog />
    </template>
  </PageSection>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
import CTAButton from '../../../../components/common/buttons/CTAButton.vue'
import ProgressBar from '../../../../components/common/elements/ProgressBar.vue'
import RobloxIdentityField from 'app/views/account/RobloxIdentityField.vue'

import VueConfirmDialog from 'vue-confirm-dialog'
import roblox from 'core/api/roblox'
const OAuth2Identities = require('collections/OAuth2Identities')
Vue.use(VueConfirmDialog)
Vue.component('VueConfirmDialog', VueConfirmDialog.default)
export default {
  name: 'AccountLinkingRewards',
  components: {
    PageSection,
    CTAButton,
    ProgressBar,
    RobloxIdentityField,
  },
  data () {
    return {
      labels: [
        {
          img: '/images/pages/roblox/podcast_social.png',
          text: '0',
        }, {
          img: '/images/pages/roblox/podcast_social_2.png',
          text: '5K',
        }, {
          img: '/images/pages/roblox/podcast_social_3.png',
          text: '10K',
        },
      ],
      robloxLogo: '/images/pages/roblox/roblox-logo.svg',
      connectListsOne: Array.from({ length: 4 }).map((_, i) => ({

        text: $.i18n.t(`roblox.connect_button_list_item_${i + 1}`),
      })),
      connectListsTwo: Array.from({ length: 4 }).map((_, i) => ({
        text: $.i18n.t(`roblox.connect_button_list_item_${i + 5}`),
      })),

      robloxIdentities: [],
      progress: 3800 / 10000,
      nextURL: window.location.href,
      isAnonymous: me.isAnonymous(),
    }
  },
  computed: {
    me () {
      return me
    },
    isConnected: {
      get () {
        return this.robloxIdentities.length > 0
      },
    },
  },
  mounted () {
    this.checkRobloxConnectionStatus()
    this.updateCounter()
  },
  methods: {
    async getRobloxIdentities () {
      const oAuth2Identities = new OAuth2Identities([])
      return oAuth2Identities.fetchForProvider('roblox')
    },
    async checkRobloxConnectionStatus () {
      this.robloxIdentities = await this.getRobloxIdentities()
    },
    async updateCounter () {
      const { count } = await roblox.getConnectionsCount()
      const MAX = 10000
      this.progress = Math.min(count / MAX, 1)
    },

    connectToRoblox () {
      if (me.isAnonymous()) {
        // login modal will appear because of the login-button class
        return
      }
      window.open('/auth/oauth2/roblox', '_blank')

      // Listen for the roblox connection to be completed so we can
      // update the UI after the user connects their roblox account
      const connectionTrackingKey = 'robloxConnectionTrackingKey'
      window.addEventListener('storage', (event) => {
        if (event.key === connectionTrackingKey) {
          this.checkRobloxConnectionStatus()
          localStorage.removeItem(connectionTrackingKey)
        }
      })
    },

    async disconnectFromRoblox (identity) {
      this.$confirm({
        message: $.i18n.t('account_settings.roblox_disconnect_confirm'),
        button: {
          no: $.i18n.t('modal.cancel'),
          yes: $.i18n.t('modal.okay'),
        },
        callback: async confirm => {
          if (confirm) {
            await identity.destroy()
            this.checkRobloxConnectionStatus()
          }
        },
      })
    },
  },
}

</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.section {
  background: linear-gradient(114.63deg, #193640 0%, #021E27 100%);
}

.roblox-progress-bar {
  max-width: 1440px;
  margin-top: 10em;
  margin-bottom: 8em;

  .progress-labels {
    position: relative;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    margin-top: 2em;

    .icon {
      position: absolute;
      top: -10em;
    }

    p {
      @extend %font-18-24;
      text-align: center;
      width: 10em;
    }
  }
}

.tail {
  display: flex;
  flex-direction: column;
  align-items: center;

  .points {
    display: flex;
    justify-content: space-between;
    max-width: 900px;
    margin-top: 40px;
    margin-bottom: 40px;

    .roblox-logo {
      max-width: min(20%, 100px);
      @media only screen and (max-width: 600px) {
        display: none;
      }
    }

    li {
      @extend %font-18-24;
      text-align: start;
    }
  }
  .content {
    margin-bottom: 40px;
  }
  .age-restriciton-warning {
    @extend %font-14;
    color:  #B4B4B4;
    margin-top: 20px;
  }
}
::v-deep .vc-text {
  color: black;
}
</style>