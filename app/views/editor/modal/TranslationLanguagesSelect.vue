<template>
  <div>
    <select
      ref="mySelect"
      multiple
    />
  </div>
</template>

<script>
import Choices from 'choices.js'
const locale = require('locale/locale')

function buildLangugaes () {
  const codes = _.keys(locale)
  const genericCodes = _.filter(codes, (code) => {
    return _.find(codes, (code2) => code2 !== code && code2.split('-')[0] === code)
  })
  const langs = []
  for (const [code, localeInfo] of Object.entries(locale)) {
    if (code in genericCodes || code.split('-')[0] === 'en') {
      continue
    }
    langs.push({
      value: code,
      label: `${localeInfo.nativeDescription}(${localeInfo.englishDescription})`,
    })
  }
  return langs
}

export default Vue.extend({
  data () {
    return {
      selectedLangs: [],
    }
  },
  mounted () {
    const choicesInstance = new Choices(this.$refs.mySelect, {
      // Choices.js options here (e.g., removeItemButton: true)
      silent: true,
      removeItemButton: true,
      choices: buildLangugaes(),
    })
    this.$refs.mySelect.addEventListener('change', (event) => {
      this.selectedLangs = choicesInstance.getValue(true)
      this.$emit('change-langs', this.selectedLangs)
    })
  },
})
</script>
<style scoped lang="scss">
@import "choices.js/src/styles/choices";
</style>