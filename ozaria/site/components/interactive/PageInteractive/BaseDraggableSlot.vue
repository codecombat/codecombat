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
          put: (this.answers.length === 0)
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
</template>

<style scoped lang="scss">
  ul {
    li {
      height: 100%;
    }
  }
</style>
