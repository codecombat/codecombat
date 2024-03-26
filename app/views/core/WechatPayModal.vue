<template>
  <modal
    title="Wechat Pay"
    :backbone-dismiss-modal="true"
  >
    <div class="wechat-pay">
      <qrcode-vue
        :value="url"
        :size="200"
        level="H"
      />
    </div>
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal'
import QrcodeVue from 'qrcode.vue'

export default Vue.extend({
  name: 'AskAIHelp',
  components: {
    Modal,
    QrcodeVue
  },
  props: {
    url: {
      type: String,
      required: true
    }
  }
})
</script>