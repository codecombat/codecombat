<template>
  <div id="modal-base-flat">
    <div class="body">
      <h1>
        {{ $t('common.warning') }}
      </h1>
      <div>
        {{ $t('editor.translate_warning_content') }}
      </div>
      <br>
      <div>{{ $t('editor.translate_pick_langs') }}</div>
      <TranslationLanguagesSelect @change-langs="onLanguageSelect" />
      <div class="buttons">
        <a
          class="btn btn-primary btn-lg"
          @click="hide"
        >{{ $t('modal.cancel') }}</a>
        <a
          class="btn btn-primary btn-lg"
          :disabled="submitting"
          @click="go"
        >{{ btnContent }}</a>
      </div>
    </div>
  </div>
</template>
<script>
import TranslationLanguagesSelect from './TranslationLanguagesSelect'
export default Vue.extend({
  name: 'TranslateConfirm',
  components: {
    TranslationLanguagesSelect,
  },
  props: {
    hide: {
      type: Function,
      default: () => {},
    },
  },
  data () {
    return {
      langs: [],
      submitting: false,
    }
  },
  computed: {
    btnContent () {
      if (this.submitting) {
        return $.i18n.t('editor.translating')
      } else {
        return $.i18n.t('editor.translate_it')
      }
    },
  },
  methods: {
    onLanguageSelect (data) {
      this.$emit('update-langs', data)
    },
    go () {
      this.submitting = true
      this.$emit('confirm-translate')
    },
  },
})
</script>
<style scoped lang="scss">
.body {
  width: 800px;
  background: #F4FAFF;
  box-shadow: 2px 2px 2px 2px #777;
  padding: 5px;
  font-size: 18px;
}
.buttons {
  width: 600px;
  display: flex;
  justify-content: space-between;
}

</style>