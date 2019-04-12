import { run, cancel } from './AbstractCommand'

export default class CommandRunner {
  constructor (commands) {
    this.commands = commands
  }

  /**
   * Runs all of the given commands.
   */
  async run () {
    for (const command of this.commands) {
      setTimeout(() => {
        command[cancel]()
      }, 50 + Math.random() * 400)
      await command[run]()
    }
  }
}
