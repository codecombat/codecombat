<script>
import VueConfirmDialog from 'vue-confirm-dialog'
import oauth2identity from 'core/api/oauth2identity'

Vue.use(VueConfirmDialog)
Vue.component('VueConfirmDialog', VueConfirmDialog.default)

export default Vue.extend({
  props: {
    userId: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      isAnonymous: me.isAnonymous(),
      robloxID: '',
    }
  },

  methods: {
    async createNewIdentity () {
      await oauth2identity.post({
        ownerID: this.userId,
        provider: 'roblox',
        profile: {
          sub: this.robloxID,
        },
      })
    },
    async onSave () {
      if (this.robloxID) {
        this.$refs.connectRobloxButton.disabled = true
        try {
          await this.createNewIdentity()
          this.$emit('saved')
        } catch (error) {
          noty({
            text: error.message,
            type: 'error',
            timeout: 5000,
          })
          this.$refs.robloxID.select()
        } finally {
          if (this.$refs.connectRobloxButton) {
            this.$refs.connectRobloxButton.disabled = false
          }
        }
      }
    },
  },
})
</script>

<template>
  <div class="roblox-id form-inline">
    <div class="form-group">
      <input
        ref="robloxID"
        v-model="robloxID"
        type="text"
        class="roblox-id__input form-control"
        placeholder="Roblox ID"
      >
      <button
        ref="connectRobloxButton"
        class="btn form-control btn-primary"
        @click="onSave"
      >
        {{ $t('account_settings.connect_roblox_button') }}
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.roblox-id {
  width: 100%;
  .form-group {
    display: flex;
    gap: 15px;
    .roblox-id__input {
      width: 100%;
    }
  }
}
</style>
