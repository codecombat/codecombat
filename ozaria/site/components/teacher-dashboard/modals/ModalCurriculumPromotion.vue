<script>
import ModalDynamicContent from './ModalDynamicContent'
import trackable from 'app/components/mixins/trackable.js'

export default Vue.extend({
  components: {
    ModalDynamicContent
  },
  mixins: [trackable],
  data: () => {
    return {
      showModal: true
    }
  },
  computed: {
    showToOldUsers () {
      const twoDaysAgo = new Date(new Date() - 2 * 24 * 60 * 60 * 1000)
      const dateCreated = new Date(me.get('dateCreated'))
      return dateCreated < twoDaysAgo && dateCreated <= new Date('2024-08-07')
    }
  },
  methods: {
    close () {
      this.$refs.modal.onClose()
    },
  }
})
</script>

<template>
  <ModalDynamicContent
    v-if="showToOldUsers"
    ref="modal"
    seen-promotions-property="curriculum-sidebar-promotion-modal"
    name="curriculum-sidebar-promotion-modal"
    :title="$t('teachers.dashboard_update')"
  >
    <template #content>
      <div class="modal-content-container">
        <img
          src="/images/common/modal/curriculum-guide-screenshot.webp"
          :alt="$t('teachers.dashboard_update')"
        >
        <p class="text-p">
          {{ $t('teachers.dashboard_update_message') }}
        </p>
        <img
          class="arrow-img"
          src="/images/common/modal/right-arrow.webp"
          :alt="$t('teachers.dashboard_update')"
        >
      </div>
    </template>
  </ModalDynamicContent>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';

.modal-content-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 10px 60px;
  text-align: center;

  .text-h2 {
    font-weight: bold;
  }

  >* {
    max-width: 600px;
  }

  img {
    width: 100%;
    max-width: 550px;
    margin: 10px auto;
  }

  .arrow-img {
    width: 100%;
    max-width: 210px;
  }
}
</style>
