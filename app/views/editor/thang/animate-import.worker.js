import {
  AdobeAnimation,
  translateToCoco
} from 'adobe-animate-parser'

self.addEventListener('message', (event) => {
  const { data } = event

  if (data.input) {
    try {
      const parser = new AdobeAnimation(data.input)
      parser.parse()

      const schema = translateToCoco(parser.parsedEntryPoint)

      self.postMessage({ output: JSON.stringify(schema) })
    } catch (error) {
      self.postMessage({ error: error.message })
    }
  }
})
