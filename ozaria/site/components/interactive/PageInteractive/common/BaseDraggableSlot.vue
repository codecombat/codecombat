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
        default: undefined
      },

      labelText: {
        type: String,
        default: ''
      },

      slotEmptyClass: {
        type: String,
        default: 'empty'
      },

      slotFilledClass: {
        type: String,
        default: 'filled'
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

      hasAnswer () {
        return this.answers.length === 1
      },

      emptyFilledClass () {
        return (this.hasAnswer) ? this.slotFilledClass : this.slotEmptyClass
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
  <div :class="[ 'slot-container', emptyFilledClass ]">
    <div
      class="expand slot-label"
    >
      {{ labelText }}
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
      display: flex;
      justify-content: center;
      align-items: center;
    }

    ul {
      position: relative;

      margin: 0;
      padding: 0;

      list-style: none;

      background-color: transparent;

      height: 100%;
      width: 100%;

      li {
        cursor: pointer;

        height: 100%;
        background-color: #FFF;

        background-image: url('/images/ozaria/interactives/drag_handle.svg');
        background-repeat: no-repeat;
        background-position: right 10px center;
        background-size: 7px 11px;
      }
    }
  }
</style>
