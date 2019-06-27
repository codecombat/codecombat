<script>
  import BaseInteractiveTitle from '../common/BaseInteractiveTitle'
  import OrderingSlots from './OrderingSlots'
  import Sortable from 'sortablejs'

  export default {
    components: {
      'base-interactive-title': BaseInteractiveTitle,
      'ordering-slots': OrderingSlots
    },

    props: {
      interactive: {
        type: Object,
        required: true
      },

      introLevelId: {
        type: String,
        required: true
      },

      interactiveSession: {
        type: Object,
        default: undefined
      },

      codeLanguage: {
        type: String
      }
    },

    data () {
      return {
        draggableGroup: Math.random().toString(),

        promptSlots: [
          { id: 1, text: 'one option' },
          { id: 2, text: 'two option' },
          { id: 3, text: 'three option' },
          { id: 4, text: 'four option' }
        ],

        answerSlots: (new Array(4)).fill(undefined)
      }
    },

    mounted () {
      const draggableUl = this.$refs['draggable-col']
      Sortable.create(draggableUl, {
        swap: true,
        onChange: e => {
          const temp = this.promptSlots[e.oldIndex]
          this.promptSlots[e.oldIndex] = this.promptSlots[e.newIndex]
          this.promptSlots[e.newIndex] = temp
        }
      })
    }
  }
</script>

<template>
  <div class="draggable-ordering-container">
    <base-interactive-title
      :interactive="interactive"
    />

    <div class="prompt-row">
      <div id='draggable-col' class='slots-container' key="draggable-col" ref="draggable-col">
        <ul v-for="prompt in promptSlots" class="draggable-slot" :key="prompt.id">
          <li>{{ prompt.text }}</li>
        </ul>
      </div>

      <ordering-slots
        v-model="answerSlots"

        :draggable-group="draggableGroup"

        class="ordering-column"
      />

      <div class="art-container">
        <img
          src="https://codecombat.com/images/pages/home/built_for_teachers1.png"
          alt="Art!"
        >
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .draggable-ordering-container {
    padding: 75px;

    display: flex;
    flex-direction: column;

    background-color: #FFF;

    /deep/ .ordering-column {
      margin-right: 10px;

      ul {
        li {
          display: flex;
          justify-content: center;
          align-items: center;

          font-weight: bold;
          font-size: 15px;
        }
      }

      .empty {
        border: 1px dashed grey;
      }
    }
  }

  .prompt-row {
    display: flex;
    flex-direction: row;

    .art-container {
      flex-grow: 1;

      padding: 0 15px 15px;

      img {
        width: 100%;
      }
    }
  }

  .slots-container {
    width: 25%;
    margin-right: 10px;

    display: flex;
    flex-direction: column;

    align-items: center;
    justify-content: space-evenly;

    /deep/ .draggable-slot {
      height: 53px;
      border: 1px solid black;

      padding: 0;
      list-style: none;
      width: 100%;
      li {
        text-align: center;
      }
    }
  }

</style>
