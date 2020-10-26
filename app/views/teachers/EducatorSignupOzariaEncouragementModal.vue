<script>
import BaseModal from 'app/components/common/BaseModal'
export default Vue.extend({
  data: () => ({
    show: true
  }),
  props: {
    onClose: {
      type: Function,
      default: () => {}
    }
  },
  components: {
    BaseModal
  },
  methods: {
    close () {
      this.show = false
      this.onClose()
    },
  }
})
</script>

<template>
  <base-modal v-if="show" id="educator-signup-encouragement-modal">
            <template slot="header">
            <div class="header">
                <h1>
                    {{ $t('teacher_ozaria_encouragement_modal.title') }}
                </h1>

                <h2>
                    {{ $t('teacher_ozaria_encouragement_modal.sub_title') }}
                </h2>

                <div class="spacer"></div>
                <button @click="close">CLOSE</button>
            </div>
        </template>
  </base-modal>
</template>