<script>
import Modal from '../../common/Modal'
import utils from 'core/utils'
import trackable from 'app/components/mixins/trackable.js'
import { mapGetters, mapMutations } from 'vuex'

export default Vue.extend({
  components: {
    Modal,
  },
  mixins: [trackable],
  props: {
    name: {
      // this name will be stored in modals store
      type: String,
      required: false,
      default () {
        return `modal-${Math.random().toString(36).substring(7)}`
      }
    },
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
      // reference to user.seenPromotions property
      // the value passed here should be added to
      // possible props of user.seenPromotions object.
      validator: function (value) {
        return typeof value === 'string' || value === null
      },
      required: false,
      default: null
    },
    cocoOnly: {
      type: Boolean,
      default: false
    },
    ozarOnly: {
      type: Boolean,
      default: false
    },
    priority: {
      type: Number,
      default: 5
    }
  },

  data () {
    return {
      showModal: true
    }
  },

  computed: {
    ...mapGetters({
      topModal: 'modals/getTopModal'
    }),
    isCodeCombat () {
      return utils.isCodeCombat
    },
    isOzaria () {
      return utils.isOzaria
    },
    modalVisible () {
      return this.topModal && this.topModal.name === this.name
    }
  },

  created () {
    if (
      this.autoShow &&
      (
        !this.seenPromotionsProperty ||
        me.shouldSeePromotion(this.seenPromotionsProperty)
      )
    ) {
      this.openModal()
    }
  },

  methods: {
    ...mapMutations({
      addModal: 'modals/addModal',
      removeModal: 'modals/removeModal'
    }),
    addModalToStore () {
      if (!this.seenPromotionsProperty || me.shouldSeePromotion(this.seenPromotionsProperty)) {
        this.addModal({
          name: this.name,
          seenPromotionsProperty: this.seenPromotionsProperty,
          priority: this.priority
        })
      }
    },
    removeModalFromStore () {
      this.removeModal(this.name)
    },
    onClose () {
      if (this.seenPromotionsProperty) {
        me.setSeenPromotion(this.seenPromotionsProperty)
        me.save()
      }
      this.hideModal()
    },
    hideModal () {
      this.removeModalFromStore()
      this.$emit('close')
    },
    openModal () {
      if ((this.cocoOnly && this.isOzaria) || (this.ozarOnly && this.isCodeCombat)) {
        return
      }

      this.addModalToStore()
      if (this.modalVisible) {
        this.$emit('open')
      }
    }
  }
})
</script>

<template>
  <div>
    <modal
      v-if="modalVisible"
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
