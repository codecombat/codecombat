describe 'utils library', ->
  require 'lib/utils'

  beforeEach ->
    fixture1 = {
      "text": "G'day, Wizard! Come to practice? Well, let's get started...",
      "i18n": {
        "es-419": {
          "text": "¡Buenas, Hechicero! ¿Vienes a practicar? Bueno, empecemos..."
        },
        "es-ES": {
          "text": "¡Buenas Mago! ¿Vienes a practicar? Bien, empecemos..."
        },
        "es": {
          "text": "¡Buenas Mago! ¿Vienes a practicar? Muy bien, empecemos..."
        },
        "fr": {
          "text": "S'lut, Magicien! Venu pratiquer? Ok, bien débutons..."
        },
        "pt-BR": {
          "text": "Bom dia, feiticeiro! Veio praticar? Então vamos começar..."
        },
        "de": {
          "text": "'N Tach auch, Zauberer! Kommst Du zum Üben? Dann lass uns anfangen..."
        },
        "tr": {
          "text": "İyi günler, Büyücü! Antremana mı geldin? Güzel, hadi başlayalım..."
        },
        "sv": {
          "text": "Godagens, trollkarl! Kommit för att öva? Nå, låt oss börja..."
        },
        "en": {
          "text": "Ohai Magician!"
        }
      },
      "sound": {
        "mp3": "db/level/52740644904ac0411700067c/gday_wizard_come_to_practice.mp3",
        "ogg": "db/level/52740644904ac0411700067c/gday_wizard_come_to_practice.ogg"
      }
    }

  it 'i18n should find a valid target string', ->
    expect(i18n(fixture1, 'text', 'en')).toEqual(fixture1.i18n.en.text)
