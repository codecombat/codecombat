<script>
  import draggable from 'vuedraggable'

  export default {
    components: {
      draggable
    },

    props: {
      numSlots: {
        type: Number,
        default: undefined
      },

      value: {
        type: Array,
        default: () => ([])
      }
    },

    data () {
      let slotData = []

      if (typeof this.numSlots !== 'undefined') {
        slotData = Array(this.numSlots)
          .fill(undefined)
          .map(() => ({ data: [] }))
      } else {
        slotData = this.value.map(s => ({ data: [ s ] }))
      }

      return {
        slotData
      }
    },

    methods: {
      changed () {
        this.$emit(
          'input',
          this.slotData.map(s => s.data[0])
        )
      }
    }
  }
</script>

<template>
  <div class="ordering-slots-container">
    <draggable
      v-for="(slot, i) in slotData"
      :key="i"

      v-model="slot.data"

      tag="ul"
      :group="{ name: 'asdf', pull: true, put: slot.data.length === 0 }"

      class="ordering-slot"

      @change="changed"
    >
      <li
        v-for="s in slot.data"
        :key="s.id"
      >
        {{ s.text }}
      </li>
    </draggable>
  </div>
</template>

<style scoped>
  .ordering-slots-container {
    width: 25%;
  }

  .ordering-slot {
    height: 40px;
    border: 1px solid black;

    padding: 0;

    list-style: none;
  }

  .ordering-slot li {
    width: 100%;
    height: 100%;
  }
</style>
