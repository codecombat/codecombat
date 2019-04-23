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
      const runPromise = command[run]()
      if (this.cancelled) {
        command[cancel]()
        continue
      }

      this.runningCommand = command

      const cancelSignalPromise = new Promise((resolve, reject) => {
        this.cancelSignal = resolve
      })

      /**
       * This race exists as a cancelled promise never resolves.
       * Thus we need a cancel signal that we can use to prevent a deadlock.
       */
      await Promise.race([runPromise, cancelSignalPromise])
      this.runningCommand = null
    }

    this.commands = null
  }

  /**
   * Cancels all commands in the commandRunner.
   */
  cancel () {
    this.cancelled = true
    if (this.runningCommand && typeof this.runningCommand[cancel] === 'function') {
      // We expect that cancelling this command will resolve the `run` promise.
      this.runningCommand[cancel]()
      if (typeof this.cancelSignal === 'function') {
        this.cancelSignal()
        this.cancelSignal = null
      }
      this.runningCommand = null
    }
  }
}
