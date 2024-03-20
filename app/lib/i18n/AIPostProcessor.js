class AIPostProcessor {
  constructor () {
    this.type = 'postProcessor'
    this.name = 'AIPostProcessor'
  }

  process (value, key, options, translator) {
    const removeAI = value.replace(/^\[AI_TRANSLATION\]/, '')
    return removeAI
  }
}
AIPostProcessor.type = 'postProcessor'
module.exports = AIPostProcessor