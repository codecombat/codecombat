<script>
  import BaseDraggableSlot from '../common/BaseDraggableSlot'

  export default {
    components: {
      'base-draggable-slot': BaseDraggableSlot
    },

    props: {
      draggableGroup: {
        type: String,
        required: true
      },

      value: {
        type: Array,
        default: () => ([])
      }
    },

    data () {
      return {
        slotData: this.value
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
    <base-draggable-slot
      v-for="(slot, i) in slotData"
      :key="i"

      v-model="slotData[i]"

      :draggable-group="draggableGroup"

      class="draggable-slot"

      @change="changed"
    />
  </div>
</template>

<style scoped lang="scss">
  .ordering-slots-container {
    width: 25%;

    display: flex;
    flex-direction: column;

    align-items: center;
    justify-content: space-evenly;

    /deep/ .draggable-slot {
      height: 55px;
      border: 1px solid black;

      padding: 0;

      width: 100%;

      ul {
        width: 100%;

        li {
          text-align: center;
        }
      }
    }
  }

  .ordering-slot li {
    width: 100%;
    height: 100%;
  }
</style>
