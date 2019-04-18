import { run, cancel } from './AbstractCommand'

/**
 * CommandRunner runs the cinematic and handles command cancellation that the
 * user may initiate.
 *
 * Once commandRunner has been cancelled every command is cancelled immediately after
 * running. Thus we only run a single dialog node at a time.
 */
export default class CommandRunner {
  constructor (commands) {
    if (!commands || (commands && !Array.isArray(commands))) {
      throw new Error(`'commands' must be an array.`)
    }
    this.commands = commands

    this.cancelled = false
    this.runningCommand = null
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
    if (!this.commands) { throw new Error('Create a new commandRunner with your new commands.') }

    for (const command of this.commands) {
      this.runningCommand = command[run]()

      if (this.cancelled) continue

      await this.runningCommand
    }

    this.commands = null
  }

  /**
   * Cancels all commands in the commandRunner.
   */
  cancel () {
    this.cancelled = true

    // We expect that cancelling this command will resolve the `run` promise.
    return this.runningCommand[cancel]()
  }
}
