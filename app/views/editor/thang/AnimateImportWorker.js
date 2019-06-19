import { AdobeAnimation, translate } from 'adobe-animate-parser'

self.addEventListener('message', (event) => {
  const { data } = event

  if (data.input) {
    try {
      const parser = new AdobeAnimation(data.input)
      parser.parse()

      self.postMessage({ output: JSON.stringify(translate(parser.parsedEntryPoint)) })
    } catch (error) {
      self.postMessage({ error })
    }
  }
})
