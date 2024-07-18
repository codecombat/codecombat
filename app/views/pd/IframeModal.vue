<template>
  <ModalDynamicPromotion
    v-if="src"
    :auto-show="false"
    :seen-promotions-property="null"
    @open="isLoading = true"
  >
    <template #content>
      <div class="iframe-modal-content">
        <loading-spinner v-if="isLoading" />
        <iframe
          class="iframe-embed"
          :src="src"
          @load="isLoading = false"
        />
      </div>
    </template>
    <template #opener="{ openModal }">
      <slot
        name="opener"
        :open-modal="openModal"
      />
    </template>
  </ModalDynamicPromotion>
</template>

<script>
import ModalDynamicPromotion from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicPromotion.vue'
import LoadingSpinner from 'app/components/common/elements/LoadingSpinner'

export default {
  name: 'SampleLessonModal',
  components: {
    ModalDynamicPromotion,
    LoadingSpinner
  },
  props: {
    src: {
      type: String,
      default: null
    }
  },
  data () {
    return {
      isLoading: true
    }
  }
}
</script>

<style lang="scss" scoped>

.iframe-modal-content {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
}

iframe.iframe-embed {
    width: 100%;
    height: 720px;
    min-width: 600px;
    margin-bottom: 30px
}
</style>