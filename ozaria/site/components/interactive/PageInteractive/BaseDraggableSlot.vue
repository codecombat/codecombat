<script>
  import draggable from 'vuedraggable'

  export default {
    components: {
      'draggable': draggable
    },

    props: {
      draggableGroup: {
        type: String,
        required: true
      },

      value: {
        type: Object,
        default: () => undefined
      },

      label: {
        type: String,
        default: () => ''
      }
    },

    data () {
      return {
        answers: (this.value) ? [ this.value ] : []
      }
    },

    computed: {
      draggableGroupConfig () {
        return {
          name: this.draggableGroup,
          pull: true,
          put: (this.answers.length === 0)
        }
      },

      displayLabel () {
        return this.answers.length === 0
      }
    },

    methods: {
      changed () {
        this.$emit(
          'input',
          this.answers[0]
        )
      }
    }
  }
</script>

<template>
  <div class="slot-container">
    <div
      class="expand slot-label"
      :style="{ display: (!displayLabel) ? 'none': undefined }"
    >
      {{ label }}
    </div>

    <draggable
      v-model="answers"
      tag="ul"
      :group="draggableGroupConfig"
      :sort="false"

      @change="changed"
    >
      <li
        v-for="answer of answers"
        :key="answer.id"
      >
        {{ answer.text }}
      </li>
    </draggable>
  </div>
</template>

<style scoped lang="scss">
  .slot-container {
    position: relative;

    .expand {
      position: absolute;

      top: 0;
      bottom: 0;
      left: 0;
      right: 0;
    }

    .slot-label {

    }

    ul {
      margin: 0;
      padding: 0;

      list-style: none;

      background-color: transparent;

      height: 100%;
      width: 100%;

      li {
        height: 100%;
      }
    }
  }
</style>
