<script>
  import StatementSlot from '../common/BaseDraggableSlot'
  import BaseInteractiveLayout from '../common/BaseInteractiveLayout'

  import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'

  export default {
    components: {
      BaseInteractiveLayout,
      'statement-slot': StatementSlot
    },

    props: {
      interactive: {
        type: Object,
        required: true
      },

      localizedInteractiveConfig: {
        type: Object,
        required: true
      },

      interactiveSession: {
        type: Object,
        default: undefined
      },

      codeLanguage: {
        type: String,
        required: true
      }
    },

    data () {
      const interactiveConfig = this.localizedInteractiveConfig || {}
      return {
        draggableGroup: Math.random().toString(),

        slotOptions: (interactiveConfig.elements || [])
          .map(({ elementId, text }) => ({
            id: elementId,
            text
          })),

        answerSlots: Array(3).fill(undefined)
      }
    },

    computed: {
      answerSlotLabels () {
        return (this.localizedInteractiveConfig || {}).labels || []
      },

      artUrl () {
        if (this.interactive.defaultArtAsset) {
          return getOzariaAssetUrl(this.interactive.defaultArtAsset)
        }

        return undefined
      }
    }
  }
</script>

<template>
  <base-interactive-layout
    :interactive="interactive"
    :art-url="artUrl"
  >
    <div class="statement-completion-content">
      <div class="slot-row">
        <statement-slot
          v-for="(slot, i) of slotOptions"
          :key="i"

          v-model="slotOptions[i]"

          :draggable-group="draggableGroup"

          class="slot"
        />
      </div>

      <div class="slot-row">
        <statement-slot
          v-for="(answerSlot, i) of answerSlots"
          :key="i"

          v-model="answerSlots[i]"

          :draggable-group="draggableGroup"

          class="slot"
          :label-text="(answerSlotLabels[i] || {}).text || ''"
        />
      </div>
    </div>
  </base-interactive-layout>
</template>

<style lang="scss" scoped>
  .statement-completion-content {
    padding: 25px;
  }

  .slot-row {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-evenly;

    margin-bottom: 20px;

    .slot {
      width: 25%;
    }
  }

  /deep/ .slot {
    height: 35px;
    border: 1px solid black;

    &.empty {
      border: 1px dashed grey;
    }

    ul {
      li {
        display: flex;
        justify-content: center;
        align-items: center;
        font-weight: bold;
        font-size: 15px;
      }
    }
  }

</style>
