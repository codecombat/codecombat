<template>
  <modal
    title="Code - Solution"
    @close="$emit('close')"
  >
    <div class="code-sol">
      <code-diff
        :language="language"
        :code-right="code"
        :code-left="solution"
        />
    </div>
  </modal>
</template>

<script>
import Modal from '../../../components/common/Modal'
import CodeDiff from '../../../../ozaria/site/components/teacher-dashboard/common/CodeDiff'
// const AceDiff = require('ace-diff')
// const aceUtils = require('../../../core/aceUtils')
export default {
  name: 'CodeSolutionModal',
  props: {
    code: {
      type: String
    },
    solution: {
      type: String
    },
    language: {
      type: String,
      default: 'javascript'
    }
  },
  components: {
    Modal,
    CodeDiff
  },
  mounted () {
    // console.log('init', this.code, this.solution, this.language, document.body.querySelector('.code-sol__ace'))
    // aceUtils.initializeACE(this.$refs.aceInit, this.language)
    // const editor = new AceDiff({
    //   element: '.code-sol__ace',
    //   mode: `/ace/mode/${this.language}`,
    //   theme: 'ace/theme/textmate',
    //   left: {
    //     content: this.code,
    //     editable: false,
    //     copyLinkEnabled: false
    //   },
    //   right: {
    //     content: this.solution,
    //     editable: false,
    //     copyLinkEnabled: false
    //   }
    // })
    // editor.editors.left.ace.setValue(this.code, -1)
    // editor.editors.right.ace.setValue(this.solution, -1)
  }
}
</script>

<style scoped lang="scss">

</style>
