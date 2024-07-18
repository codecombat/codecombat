<script>
import Modal from '../../common/Modal'
import utils from 'core/utils'
import trackable from 'app/components/mixins/trackable.js'

export default Vue.extend({
  components: {
    Modal,
  },
  mixins: [trackable],
  props: {
    title: {
      type: String,
      default: null,
      required: false
    },
    autoShow: {
      type: Boolean,
      default: true,
      required: false
    },
    seenPromotionsProperty: {
      validator: function (value) {
        return typeof value === 'string' || value === null
      },
      required: true
    },
    cocoOnly: {
      type: Boolean,
      default: false
    },
    ozarOnly: {
      type: Boolean,
      default: false
    }
  },

  data: () => {
    return {
      showModal: true
    }
  },

  computed: {
    isCodeCombat () {
      return utils.isCodeCombat
    },
    isOzaria () {
      return utils.isOzaria
    }
  },

  watch: {
    showModal (newVal) {
      if (this.cocoOnly && this.isOzaria && newVal) {
        this.hideModal()
      }
      if (this.ozarOnly && this.isCodeCombat && newVal) {
        this.hideModal()
      }
    }
  },

  created () {
    if (!this.autoShow) {
      this.showModal = false
    } else if (this.seenPromotionsProperty) {
      this.showModal = !me.getSeenPromotion(this.seenPromotionsProperty)
    }
  },

  methods: {
    close () {
      if (this.seenPromotionsProperty) {
        me.setSeenPromotion(this.seenPromotionsProperty)
        me.save()
      }
      this.hideModal()
    },
    hideModal () {
      this.showModal = false
      this.$emit('close')
    },
    onClose () {
      this.close()
    },
    openModal () {
      this.$emit('open')
      this.showModal = true
    }
  }
})
</script>

<template>
  <div>
    <modal
      v-if="showModal"
      :title="title"
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      @close="onClose"
    >
      <slot name="content" />
    </modal>
    <slot
      name="opener"
      :open-modal="openModal"
    />
  </div>
</template>

<style lang="scss" scoped>
$header-height: 71px;
::v-deep {
  .modal-mask-fade {
    padding-top: $header-height
  }
  .ozaria-modal-content {
    max-height: calc(95vh - #{$header-height});
  }
}
</style>
