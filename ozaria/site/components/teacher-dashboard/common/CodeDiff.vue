<script>
  const AceDiff = require('ace-diff')

  const aceEditModes = {
    javascript: 'ace/mode/javascript',
    coffeescript: 'ace/mode/coffee',
    python: 'ace/mode/python',
    lua: 'ace/mode/lua',
    java: 'ace/mode/java',
    html: 'ace/mode/html'
  }

  export default {
    props: {
      codeLeft: {
        type: String,
        required: true
      },
      codeRight: {
        type: String,
        required: true
      },
      language: {
        type: String,
        required: true
      }
    },

    data: () => ({
      codeDiff: null
    }),

    watch: {
      codeLeft (val, oldVal) {
        if (val !== oldVal && this.codeDiff) {
          this.codeDiff.editors.left.ace.setValue(val.trim(), -1)
        }
      },
      codeRight (val, oldVal) {
        if (val !== oldVal && this.codeDiff) {
          this.codeDiff.editors.right.ace.setValue(val.trim(), -1)
        }
      }
    },

    mounted () {
      this.codeDiff = this.createAceDiff('.code-diff-component')
    },

    beforeDestroy () {
      this.codeDiff.destroy()
    },

    methods: {
      createAceDiff (el) {
        const diffView = new AceDiff({
          element: el,
          mode: aceEditModes[this.language],
          theme: 'ace/theme/textmate',
          left: {
            content: this.codeLeft,
            editable: false,
            copyLinkEnabled: false
          },
          right: {
            content: this.codeRight,
            editable: false,
            copyLinkEnabled: false
          }
        })
        return diffView
      }
    }
  }
</script>

<template>
  <div
    ref="code"
    class="code-diff-component"
  >
  </div>
</template>

<style lang="sass">
  /* could not be scoped */
  @import 'app/styles/common/ace-diff.sass'
</style>

<style lang="sass" scoped>
  .code-area-component
    width: 100%
</style>
