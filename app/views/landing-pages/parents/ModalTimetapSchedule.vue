<script>
  import BaseModal from 'app/components/common/BaseModal'

  export default {
    components: {
      BaseModal
    },

    props: {
      show: {
        type: Boolean,
        default: false
      },

      classType: {
        type: String,
        default: undefined
      }
    },

    computed: {
      // Note this is not used because changing the page url causes a reload, which makes
      // the pre load of this iframe useless
      timetapIframeUrl () {
        if (this.classType === undefined) {
          return 'https://codecombat.timetap.com?utm_campaign=timetapliveclasses&utm_source=codecombat&utm_medium=modal'
        } else if (this.classType === 'group') {
          return 'https://www.timetap.com/appts/jPlOQTv7JXIJ?utm_campaign=timetapliveclasses&utm_source=codecombat&utm_medium=modal'
        } else if (this.classType === 'private') {
          return 'https://www.timetap.com/appts/wPvlbTkKwauE?utm_campaign=timetapliveclasses&utm_source=codecombat&utm_medium=modal'
        }
      }
    },

    methods: {
      onWindowMessage (event) {
        if (event.source === this.$refs.timetapIframe.contentWindow && event.data === 'class.booked') {
          this.$emit('booked')
        }
      }
    },

    mounted () {
      window.addEventListener('message', this.onWindowMessage, false)
    },

    beforeDestroy () {
      window.removeEventListener('message', this.onWindowMessage)
    }
  }
</script>

<template>
  <base-modal :class="[ !show ? 'hide' : undefined, 'timetap-modal']">
    <template slot="header">
      {{ $t('parents_landing_2.book_your_class') }}
      <span class="glyphicon glyphicon-remove close" @click="$emit('close')"></span>
    </template>

    <template slot="body">
      <!-- Temporarily removed 'sandbox="allow-same-origin allow-scripts"' for TimeTap to debug sessionStorage error -->
      <iframe ref="timetapIframe" src="https://codecombat.timetap.com?utm_campaign=timetapliveclasses&utm_source=codecombat&utm_medium=modal" />
    </template>
  </base-modal>
</template>

<style scoped>
  .hide {
    display: none;
  }

  .timetap-modal ::v-deep .modal-container {
    width: 700px;
    max-width: 100%;

    height: 900px;
    max-height: 100%;
  }

  .timetap-modal ::v-deep .modal-body {
    padding-left: 4px;
    padding-right: 4px;

    flex-direction: column;
  }

  .timetap-modal ::v-deep .modal-footer {
    margin: 0;
    padding: 0;
    height: 4px;
  }

  .timetap-modal iframe {
    flex-grow: 1;
    width: 100%;
    height: 100%;
  }

  .close {
    position: absolute;
    right: 0;

    height: 100%;
    display: flex;
    align-items: center;

    margin-right: 10px;

    cursor: pointer;
  }
</style>
