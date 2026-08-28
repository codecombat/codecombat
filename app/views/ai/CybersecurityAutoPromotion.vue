<script>
import ModalDynamicPromotion from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent'
import CyberSecurityComponent from './CyberSecurityComponent'
import utils from 'app/core/utils'

const dayjs = window.dayjs
export default {
  components: {
    ModalDynamicPromotion,
    CyberSecurityComponent,
  },
  computed: {
    showPromotion () {
      const aweekago = dayjs().subtract(1, 'week')
      return utils.isCodeCombat && aweekago.isAfter(me.get('dateCreated')) && dayjs().isBefore('2026-09-30')
    },
  },
  methods: {
    onClose () {
      this.$refs.modal.onClose()
    },
  },
}
</script>

<template>
  <div class="promotion-modal">
    <ModalDynamicPromotion
      v-if="showPromotion"
      ref="modal"
      modal-type="newModal"
      seen-promotions-property="cyber-security-promotion-modal"
    >
      <template #content>
        <CyberSecurityComponent
          @close="onClose"
        />
      </template>
    </ModalDynamicPromotion>
  </div>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';
@import 'app/styles/component_variables.scss';
</style>