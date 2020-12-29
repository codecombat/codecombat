import { getFadeFromBlack, getFadeToBlack } from '../../../../app/schemas/models/selectors/cinematic'
import { AnimeCommand, SyncFunction } from '../commands/commands'
import anime from 'animejs/lib/anime.es.js'

const FADE_ID = 'fade-container'

export default class FadeSystem {
  constructor () {
    this.seenFirstFadeToBlack = false
  }

  parseDialogNode (dialogNode) {
    const fadeFromSettings = getFadeFromBlack(dialogNode)
    const commands = []
    if (fadeFromSettings) {
      // If we want to fade from black and no command has yet set up the fade container,
      // we synchronously set up the container ready to fade from.
      if (!this.seenFirstFadeToBlack) {
        const fadeContainer = document.getElementById(FADE_ID)
        if (fadeContainer) {
          fadeContainer.style.opacity = 1
        }
      }

      const fadeFromBlackCommand = new AnimeCommand(() => {
        return anime.timeline({
          autoplay: false
        }).add({
          targets: `#${FADE_ID}`,
          duration: fadeFromSettings.duration || 400,
          opacity: 0,
          easing: 'easeInCubic'
        })
      })

      fadeFromBlackCommand.undoCommandFactory = () => {
        return new SyncFunction(() => {
          document.getElementById(FADE_ID).style.opacity = 1
        })
      }

      commands.push(fadeFromBlackCommand)

      return commands
    }

    const fadeToSettings = getFadeToBlack(dialogNode)
    if (fadeToSettings) {
      this.seenFirstFadeToBlack = true

      const fadeToBlackCommand = new AnimeCommand(() => {
        return anime.timeline({
          autoplay: false
        }).add({
          targets: `#${FADE_ID}`,
          duration: fadeToSettings.duration || 400,
          opacity: 1,
          easing: 'easeOutCubic'
        })
      })

      fadeToBlackCommand.undoCommandFactory = () => {
        return new SyncFunction(() => {
          document.getElementById(FADE_ID).style.opacity = 0
        })
      }
      commands.push(fadeToBlackCommand)
    }

    return commands
  }
}
