<script>
const ace = require('lib/aceContainer')

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
    code: {
      type: String,
      required: true
    },
    language: {
      type: String,
      required: true
    }
  },

  data: () => ({
    codeEditor: null
  }),

  computed: {
    trimmedCode () {
      return this.code.trim()
    }
  },

  watch: {
    code (val, oldVal) {
      if (val !== oldVal && this.codeEditor) {
        this.codeEditor.setValue(this.trimmedCode)
        // Clear the selection that occurs after value changes.
        this.codeEditor.clearSelection()
      }
    }
  },

  mounted () {
    this.codeEditor = this.createAceEditor(this.$refs.code)
    this.codeEditor.setValue(this.trimmedCode)
    this.codeEditor.clearSelection()
  },

  beforeDestroy () {
    this.codeEditor.destroy()
  },

  methods: {
    createAceEditor (el) {
      const editor = ace.edit(el)
      editor.setOptions({ maxLines: Infinity })
      editor.setReadOnly(true)
      editor.setTheme('ace/theme/textmate')
      editor.setShowPrintMargin(false)
      editor.setShowFoldWidgets(false)
      editor.setHighlightActiveLine(false)
      editor.setBehavioursEnabled(false)
      editor.renderer.setShowGutter(false)
      editor.clearSelection()
      const session = editor.getSession()
      // session.setUseWorker(false)
      session.setMode(aceEditModes[this.language])
      session.setWrapLimitRange(null)
      session.setUseWrapMode(false)
      session.setNewLineMode('unix')
      editor.setShowInvisibles(false)
      editor.setBehavioursEnabled(false)
      editor.setAnimatedScroll(false)
      // editor.$blockScrolling = Infinity
      editor.renderer.setShowGutter(false)

      editor.setOptions({
        fontSize: '12px'
      })
      editor.container.style.lineHeight = 1.6

      return editor
    }
  }
}
</script>

<template>
  <div
    ref="code"
    class="code-area-component"
  >
    {{ trimmedCode }}
  </div>
</template>

<style lang="scss">

  .code-area-component .ace_scroller {
    box-shadow: inset 1px 2px 6px rgba(0, 0, 0, 0.06);
    border: 0.5px solid #d8d8d8;
    border-radius: 4px;
  }

  .code-area-component .ace_hidden-cursors {
    opacity: 0;
  }

</style>

<style lang="scss" scoped>
  .code-area-component {
    width: 100%;
  }

</style>
