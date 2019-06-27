<script>
  import VueDraggable from 'vuedraggable'

  import BaseInteractiveLayout from '../common/BaseInteractiveLayout'
  import { getOzariaAssetUrl } from '../../../../common/ozariaUtils'

  export default {
    components: {
      BaseInteractiveLayout,
      'draggable': VueDraggable
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
      return {
        promptSlots: (this.localizedInteractiveConfig.elements || [])
          .map(({ elementId, ...rest }) => ({
            ...rest,
            id: elementId
          }))
      }
    },

    computed: {
      labels () {
        return (this.localizedInteractiveConfig.labels || []).map((label) => {
          if (typeof label === 'string') {
            return { text: label }
          }

          return label
        })
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
    <div class="draggable-ordering-content">
      <draggable
        :list="promptSlots"
        class="slots-container prompt-slots"
        ghost-class="ghost-slot"
        tag="ul"
        :force-fallback="true"
        fallback-class="dragging-slot"
      >
        <li
          v-for="prompt in promptSlots"
          :key="prompt.id"
          :class="{ 'prompt': true, 'monospaced': (prompt.textStyleCode === true) }"
        >
          {{ prompt.text }}
        </li>
      </draggable>

      <ul
        class="slots-container"
      >
        <li
          v-for="(label, index) in labels"
          :key="index"
          :class="{ 'prompt-label': true, 'monospaced': (label.textStyleCode === true) }"
        >
          {{ label.text }}
        </li>
      </ul>
    </div>
  </base-interactive-layout>
</template>

<style lang="scss" scoped>
  .draggable-ordering-content {
    padding: 20px;

    display: flex;
    flex-direction: row;

    align-items: center;
    justify-content: center;

    height: 100%;
  }

  ul.slots-container {
    height: 100%;
    width: 50%;

    max-width: 500px;

    padding: 0;

    margin: 0;
    margin-right: 10px;

    display: flex;
    flex-direction: column;

    align-items: center;
    justify-content: space-evenly;

    li {
      margin-bottom: 15px;

      width: 100%;

      display: flex;

      justify-content: center;
      align-items: center;

      text-align: center;
      font-size: 15px;

      min-height: 50px;
    }

    li.prompt {
      border: 2px solid #acb9fa;
    }

    li.prompt-label {
      background-color: #acb9fa;
      border: 2px solid #acb9fa;
    }

    li.monospaced {
      font-family: monospace;
    }

    li.dragging-slot {
      // TODO this doesn't work because vue-draggable also uses transforms for positioing
      transform: rotate(5deg);
    }
  }
</style>
