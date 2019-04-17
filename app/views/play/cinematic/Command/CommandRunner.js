import { run, cancel } from './AbstractCommand'

/**
 * CommandRunner runs the cinematic and handles command cancellation that the
 * use may initiate.
 */
export default class CommandRunner {
  constructor (commands) {
    this.commands = commands
  }

  /**
   * Runs the commands that are internally stored.
   * The commands must be extended from the `AbstractCommand` class.
   *
   * Commands are run with imported unique symbols, allowing protected methods to be run.
   *
   * A command is run with:
   *
   * ```js
   * command[run]()
   * ```
   *
   * and cancelled with:
   *
   * ```js
   * command[cancel]()
   * ```
   */
  async run () {
    for (const command of this.commands) {
      await command[run]()
    }
  }
}
