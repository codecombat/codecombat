co = require 'co'
errors = require '../commons/errors'
fs = require 'fs'
textToSpeech = require '@google-cloud/text-to-speech'

synthesize = co.wrap (text='Hello World', options={}) ->
  unless text
    throw new errors.UnprocessableEntity '"text" to synthesize required'
  client = new textToSpeech.TextToSpeechClient()
  language = options.language ? 'en-US'
  language = {'es-419': 'es-ES', 'nl-BE': 'nl-NL', 'fr': 'fr-FR', 'de-AT': 'de-DE', 'de-CH': 'de-DE', 'pt-PT': 'pt-BR', 'ja': 'ja-JP', 'sv': 'sv-SE', 'tr': 'tr-TR'}[language] ? language
  if language isnt 'en-US'
    response = yield client.listVoices {languageCode: language}
    voices = response[0].voices
    if voiceChoice = _.sample voices
      voice =
        name: voiceChoice.name
        languageCode: voiceChoice.languageCodes[0]
    else
      return null
  voice ?=
    name: 'en-US-Wavenet-C'
    languageCode: 'en-US'
  request =
    input:
      text: text
    voice: voice
    audioConfig:
      audioEncoding: if options.audioEncoding is 'OGG' then 'OGG_OPUS' else 'MP3'
      #pitch: 20  # Experimental pitch control from -20 to 20
      #speakingRate: 0.5  # Experimental speed control from 0.5 to 2.0
  response = yield client.synthesizeSpeech(request)
  return response[0].audioContent

module.exports = {
  synthesize
}
