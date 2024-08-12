<template>
  <ModalDynamicContent
    v-if="src"
    :auto-show="false"
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
  </ModalDynamicContent>
</template>

<script>
import ModalDynamicContent from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent.vue'
import LoadingSpinner from 'app/components/common/elements/LoadingSpinner'

export default {
  name: 'SampleLessonModal',
  components: {
    ModalDynamicContent,
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