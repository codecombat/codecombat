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
          put: (typeof value === 'undefined')
        }
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
  <draggable
    v-model="answers"
    tag="ul"
    :group="draggableGroupConfig"

    @change="changed"
  >
    <li
      v-for="answer of answers"
      :key="answer.id"
    >
      {{ answer.text }}
    </li>
  </draggable>
</template>

<style scoped>
</style>
