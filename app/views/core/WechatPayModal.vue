<template>
  <modal
    title="微信扫一扫支付"
    :backbone-dismiss-modal="true"
  >
    <div
      v-if="payment === 'starting'"
      class="wechat-pay"
    >
      <qrcode-vue
        :value="url"
        :size="200"
        level="H"
      />
    </div>
    <div
      v-else
      class="wechat-pay"
    >
      <p>支付已完成，将为您刷新页面...</p>
    </div>
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal'
import QrcodeVue from 'qrcode.vue'
import { querySession } from 'core/api/wechat'

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
    },
    sessionId: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      interval: 5000,
      payment: 'starting'
    }
  },
  mounted () {
    setTimeout(() => {
      this.querySession()
    }, this.interval)
  },
  methods: {
    async querySession () {
      const session = await querySession(this.sessionId)
      if (session?.status === 'WECHATPAY_PROCESSED') {
        this.payment = 'done'
        setTimeout(() => {
          location.reload()
        }, 2000)
      } else {
        setTimeout(() => {
          this.querySession()
        }, this.interval)
      }
    }
  }
})
</script>