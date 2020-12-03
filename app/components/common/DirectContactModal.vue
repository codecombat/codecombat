<script>
  import ModalDivider from 'app/components/common/ModalDivider'
  import Modal from 'app/components/common/Modal'

  export default Vue.extend({
    components: {
      ModalDivider,
      Modal
    },
    data: () => ({
      zendeskError: null
    }),
    methods: {
      programaticallyClose () {
        // Because this modal is created from Backbone, we don't have a clean way to
        // close the modal other than interacting with data-dismiss='modal' through clicking.
        $('#coco-modal-header-close-button').click()
      },
      clickedChat () {
        try {
          window.tracker.drift.openChat()
          this.programaticallyClose()
        } catch (e) {
          console.error(e)
          noty({
            text: 'Unable to load chat (may be due to browser privacy features)',
            layout: 'topCenter',
            type: 'error',
            timeout: 5000
          })
        }
      },
      clickedEmail () {
        try {
          zE('webWidget', 'prefill', {
            email: {
              value: me.get('email')
            }
          })
          zE('webWidget', 'open')
          zE('webWidget', 'show')
          this.programaticallyClose()
        } catch (e) {
          console.error(e)
          noty({
            text: 'Unable to load message in browser (may be due to browser privacy features)',
            layout: 'topCenter',
            type: 'error',
            timeout: 5000
          })
          this.zendeskError = true
        }
      }
    }
  })
</script>

<template>
  <modal
      :backbone-dismiss-modal="true"
      :title="$t('general.contact_us')"
  >
    <div class="flex-container">
      <div class="flex-container">
        <p>{{ $t("general.chat_with_us") }} (9am-6pm ET)</p>
        <button @click.prevent="clickedChat" class="btn btn-large btn-primary btn-moon">{{ $t("general.chat") }}</button>
      </div>

      <modal-divider />

      <div v-if="zendeskError">
        {{ $t('general.email_us') }}: <a href="mailto:support@codecombat.com">support@codecombat.com</a>
      </div>
      <div v-else class="flex-container">
        <p>{{ $t("general.email_us") }}</p>
        <button @click.prevent="clickedEmail" class="btn btn-large btn-primary btn-moon">{{ $t("general.email") }}</button>
      </div>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
@import "app/styles/style-flat-variables";
@import "app/styles/core/variables";

.flex-container {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

// These types of buttons could be shared better
.btn-primary.btn-moon {
  background-color: $moon;
  border-radius: 1px;
  color: $gray;
  text-shadow: unset;
  font-weight: bold;
  @include font-h-5-button-text-black;
  min-width: 260px;
  padding: 15px 0;
  background-image: unset;
  margin: 0 15px;

  &:hover {
    @include font-h-5-button-text-white;
    background-color: $goldenlight;
    transition: background-color .35s;
  }
}
</style>
