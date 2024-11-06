<script>
import ModalDynamicPromotion from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent'
import HackstackPromotionComponent from './HackstackPromotionComponent'
export default {
  components: {
    ModalDynamicPromotion,
    HackstackPromotionComponent,
  },
  methods: {
    openModalDynamicPromotion () {
      this.modalDynamicPromotion = true
    },
  },
}
</script>

<template>
  <div class="promotion-modal">
    <ModalDynamicPromotion
      ref="modal"
      seen-promotions-property="new-hackstack-promotion-modal"
    >
      <template #content>
        <HackstackPromotionComponent />
      </template>
    </ModalDynamicPromotion>
  </div>
</template>

<style scoped>
</style>
