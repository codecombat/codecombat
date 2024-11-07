<script>
import ModalDynamicPromotion from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent'
import HackstackPromotionComponent from './HackstackPromotionComponent'
export default {
  components: {
    ModalDynamicPromotion,
    HackstackPromotionComponent,
  },
  computed: {
    showPromotion () {
      return new Date() <= new Date('2024-11-30')
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
      seen-promotions-property="new-hackstack-promotion-modal"
    >
      <template #content>
        <HackstackPromotionComponent
          @close="onClose"
        />
      </template>
    </ModalDynamicPromotion>
  </div>
</template>

<style scoped>
::v-deep .ozaria-modal-body{
  overflow-y: auto !important;
}
::v-deep .image {
  width: 70%;
  margin-left: auto !important;
  margin-right: auto !important;
  margin-bottom: 40px !important;
}
::v-deep .banner-img {
  width: 200px !important;
  bottom: -25px !important;
}
</style>
