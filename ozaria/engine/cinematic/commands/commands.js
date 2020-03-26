import AbstractCommand, { run, cancel } from './AbstractCommand'
import Promise from 'bluebird'
import CommandRunner from './CommandRunner'

Promise.config({
  cancellation: true
})

/**
 * Returns a promise that will resolve after an approximate number of milliseconds.
 * The benefit of using this over setTimeout is that this works better when
 * users tab away or lose focus of the page. setTimeouts won't wait when the
 * user has tabbed away.
 *
 * @param {number} ms Time in milliseconds to wait.
 */
function sleep (ms) {
  return new Promise((resolve, reject) => {
    let totalTime = 0
    const update = () => {
      if (totalTime > ms) return resolve()
      window.requestAnimationFrame(update)
      totalTime += 16.66 // 1 frame at 60 fps
    }
    window.requestAnimationFrame(update)
  })
}

/**
 * Command for sleeping the cinematic system.
 *
 * Can be composed with a sequence command to simulate a delay.
 */
export class Sleep extends AbstractCommand {
  constructor (ms) {
    super()
    this.ms = ms
  }

  run () {
    return sleep(this.ms)
  }
}

/**
 * AnimeCommand is used to turn animejs animation tweens into commands that the Command Runner can play and cancel.
 */
export class AnimeCommand extends AbstractCommand {
  /**
   * @param {() => anime} animation A function that returns an animation
   */
  constructor (animation) {
    super()
    this.animationFn = animation
  }

  /**
   * Starts the animation, returning a cancellable promise that resolves when
   * animation completes.
   */
  run () {
    return new Promise((resolve, reject) => {
      this.animation = this.animationFn()
      this.animation.play()
      this.animation.complete = resolve
    })
  }

  /**
   * Cancel method ignores the promise and simply moves the animation
   * to the end.
   */
  cancel (promise) {
    const animation = this.animation
    animation.seek(animation.duration)
    return promise
  }
}

/**
 * SyncFunction runs a synchronous function.
 */
export class SyncFunction extends AbstractCommand {
  /**
   * @param {Function} runFn Synchronous function that doesn't return anything.
   */
  constructor (runFn) {
    super()
    this.run = () => {
      runFn()
      return Promise.resolve()
    }
    this.cancel = () => {}
  }
}

export class Noop extends AbstractCommand {
  run () {
    return Promise.resolve()
  }
}

/**
 * Higher order command that operates on other commands.
 * Takes in a list of commands and operates on them sequentially.
 *
 * Cancelling this command sequentially cancels all included commands.
 *
 * Usage traditionally is for adding delays. I.e. Sleep command and then another command.
 */
export class SequentialCommands extends AbstractCommand {
  /**
   * @param {AbstractCommand[]} commands - List of commands to run sequentially.
   */
  constructor (commands) {
    super()
    this.commandRunner = new CommandRunner(commands)
  }

  [run] () {
    return this.run()
  }

  run () {
    return this.commandRunner.run()
  }

  [cancel] () {
    this.cancel()
  }

  cancel () {
    this.commandRunner.cancel()
  }
}

/**
 * ConcurrentCommands runs commands concurrently.
 * It only resolves once all inner commands have completed.
 */
export class ConcurrentCommands extends AbstractCommand {
  /**
   * @param {AbstractCommand[]}  commands - List of commands to run concurrently
   */
  constructor (commands) {
    super()
    this.commands = commands
  }

  run () {
    return Promise.all([
      Promise.resolve(),
      ...this.commands.map(c => c[run]())
    ])
  }

  cancel () {
    this.commands.forEach(c => {
      c[cancel]()
    })
  }
}
