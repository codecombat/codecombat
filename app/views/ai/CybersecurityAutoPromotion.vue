<script>
import ModalDynamicPromotion from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent'
import CyberSecurityComponent from './CyberSecurityComponent'
export default {
  components: {
    ModalDynamicPromotion,
    CyberSecurityComponent,
  },
  computed: {
    showPromotion () {
      return true
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