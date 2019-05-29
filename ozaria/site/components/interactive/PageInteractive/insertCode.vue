<script>
  import { codemirror } from 'vue-codemirror'
  import 'codemirror/lib/codemirror.css'

  export default {
    components: {
      codemirror
    },

    props: {
      interactive: {
        type: Object,
        required: true,
        default: () => ({})
      },

      introLevelId: {
        type: String,
        required: true,
        default: ''
      },

      interactiveSession: {
        type: Object
      },

      courseInstanceId: {
        type: String
      }
    },

    data () {
      return {
        codemirrorOptions: {
          tabSize: 2,
          mode: 'text/javascript',
          lineNumbers: true,
          readOnly: 'nocursor'
        }
      }
    },

    computed: {
      code () {
        return 'let x = "y"'
      }
    }
  }
</script>

<template>
  <div class="interactive-container">
    <div class="question-container">
      <div class="question">
        <h2>Question</h2>
        <ul>
          <li>choice.one()</li>
          <li>choice.two()</li>
          <li>choice.three()</li>
          <li>choice.four()</li>
        </ul>
      </div>
      <div class="answer">
        <codemirror :value="code" :options="codemirrorOptions"></codemirror>
      </div>
    </div>
    <div class="art-container">
      <img
        src="https://codecombat.com/images/pages/home/built_for_teachers1.png"
        alt="Art!"
      >
    </div>
  </div>
</template>

<style scoped>
  .interactive-container {
    display: flex;
    flex-direction: row;

    background-color: #FFF;
  }

  .interactive-container .art-container {
    flex-grow: 1;

    padding: 15px;
  }

  .interactive-container .art-container img {
    width: 100%;
  }

  .interactive-container .question-container {
    width: 30%;

    display: flex;
    flex-direction: column;
  }

  .interactive-container .question-container .question {
    height: 30%;
    width: 100%;
  }

  .interactive-container .question-container .answer {
    width: 100%;

    flex-grow: 1;
  }
</style>
