<template>
  <ModalDynamicContent
    ref="modal"
    :auto-show="false"
    :title="$t('teacher_dashboard.ozaria_hs_modal_title')"
  >
    <template #content>
      <div class="ozar-hs-modal-content">
        <mixed-color-label
          :text="$t('teacher_dashboard.ozaria_hs_modal_blurb')"
        />
      </div>
    </template>
  </ModalDynamicContent>
</template>

<script>
import ModalDynamicContent from 'ozaria/site/components/teacher-dashboard/modals/ModalDynamicContent.vue'
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default {
  name: 'OzariaHackStackModal',
  components: {
    ModalDynamicContent,
    MixedColorLabel
  },
  methods: {
    openModal () {
      this.$refs.modal.openModal()
    },
  },
}
</script>

<style lang="scss" scoped>
.ozar-hs-modal-content {
    max-width: min(600px, 90vw);
}
</style>