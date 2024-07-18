<script>
import ModalDynamicPromotion from './ModalDynamicPromotion'
import trackable from 'app/components/mixins/trackable.js'

export default Vue.extend({
  components: {
    ModalDynamicPromotion
  },
  mixins: [trackable],
  props: {
    curriculumClicked: {
      type: Boolean,
      required: false
    }
  },
  data: () => {
    return {
      showModal: true
    }
  },
  computed: {
    isOld () {
      const twoDaysAgo = new Date(new Date() - 2 * 24 * 60 * 60 * 1000)
      return new Date(me.get('dateCreated')) < twoDaysAgo
    }
  },
  watch: {
    curriculumClicked (newVal, oldVal) {
      if (newVal) {
        this.showModal = false
      }
    },
  },
  methods: {
    onShow () {
      if (this.isOld) {
        this.showModal = true
        this.$emit('show')
      } else {
        this.showModal = false
      }
    },
    onClose () {
      this.showModal = false
      this.$emit('close')
    }
  }
})
</script>

<template>
  <div>
    <ModalDynamicPromotion
      v-if="showModal"
      ref="modal"
      seen-promotions-property="curriculum-sidebar-promotion-modal"
      :title="$t('teachers.dashboard_update')"
      @show="onShow"
      @close="onClose"
    >
      <template #content>
        <div class="modal-content-container">
          <img
            src="/images/common/modal/curriculum-guide-screenshot.png"
            :alt="$t('teachers.dashboard_update')"
          >
          <p class="text-p">
            {{ $t('teachers.dashboard_update_message') }}
          </p>
          <img
            class="arrow-img"
            src="/images/common/modal/right-arrow.png"
            :alt="$t('teachers.dashboard_update')"
          >
        </div>
      </template>
    </ModalDynamicPromotion>
  </div>
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
