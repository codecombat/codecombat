<template>
  <a
    class="button-a"
    target="_blank"
    @click.prevent.stop="handle"
  >
    <div class="text">{{ text }}</div>
    <div class="qr" v-if="showQR">
      微信扫码添加王老师申请CodeQuest 2024
      <img src="/images/pages/codequest/qr_bill.png" alt="QR Code" />
    </div>
  </a>
</template>

<script>
export default {
  name: 'ButtonA',
  props: {
    text: {
      type: String,
      default: 'Button_A'
    },
    apply: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    china () {
      return features.china
    }
  },
  data () {
    return {
      showQR: false
    }
  },
  methods: {
    handle (e) {
      if (this.china && this.apply) {
        this.showQR = true
        setTimeout(() => {
          this.showQR = false
        }, 20000)
        e.stopPropagation()
        return false
      } else {
        const href = this.$attrs['href']
        if (href) {
          window.open(href, '_blank')
        }
      }
    }
  }
}
</script>

<style scoped lang="scss">
.button-a {
  align-items: center;
  border-radius: 8px;
  display: flex;
  gap: 8px;
  justify-content: center;
  overflow: visible;
  padding: 12px 20px;
  position: relative;
  width: 160px;
  cursor:pointer;
  text-decoration: none;
}

.button-a .text {
  color: #111928;
  font-family: "Plus Jakarta Sans-ExtraBold", Helvetica;
  font-size: 18px;
  font-weight: 800;
  letter-spacing: 0;
  line-height: 24px;
  margin-top: -1px;
  position: relative;
  white-space: nowrap;
  width: fit-content;
  text-decoration: none;
}

.button-a {
  background: #4DECF0;
}

.qr {
  position: absolute;
  z-index: 999;
  top: 100%;
  background: #f0fdfd;
  color: black;
  width: 20em;
  height: 22em;
}

</style>
