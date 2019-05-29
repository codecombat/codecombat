<script>
  import draggable from 'vuedraggable'

  export default {
    components: {
      draggable
    },

    props: {
      draggableGroup: {
        type: String,
        required: true
      },

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
          .map(() => [])
      } else {
        slotData = this.value.map(s => [ s ])
      }

      return {
        slotData
      }
    },

    methods: {
      changed () {
        this.$emit(
          'input',
          this.slotData.map(s => s[0])
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

      v-model="slotData[i]"

      tag="ul"
      :group="{ name: draggableGroup, pull: true, put: true }"

      class="ordering-slot"

      @change="changed"
    >
      <li
        v-for="s in slotData[i]"
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
