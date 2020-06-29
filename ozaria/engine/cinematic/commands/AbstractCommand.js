// Throws an error if `import ... from ..` syntax.
const Promise = require('bluebird')

Promise.config({
  cancellation: true
})

/**
 * These symbols can be exported in order to call the protected `AbstractCommand` methods.
 */
export const run = Symbol('private run method')
export const cancel = Symbol('cancellation symbol')

/**
 * AbstractCommand is the abstract base class for objects that can be run in the CommandRunner.
 *
 * The simplest implementaion of this class is a command that does nothing. Let's call it the `Noop` command.
 *
 * ```js
 * export class Noop extends AbstractCommand {
 *   run () {
 *     return Promise.resolve()
 *   }
 * }
 * ```
 *
 * All you need to do to extend this class is implement a new `run` method.
 *
 * This method should return a **cancellable** promise.
 * I recommend using bluebird for this. See the AbstractCommand tests for examples.
 *
 * If you need to implement your own specific cancel logic you can overwrite the `.cancel` method.
 *
 * There are two protected methods that you shouldn't touch used by the CommandRunner to run your command.
 * @abstract
 */
export default class AbstractCommand {
  constructor () {
    if (this.constructor === AbstractCommand) {
      throw new Error('This is an abstract class that you must extend.')
    }
  }

  /**
   * This method should not be overridden.
   * It checks that the promise returned from run is valid, and also remembers
   * the promise so it can be cancelled.
   */
  [run] () {
    this.promise = this.run()
    if (!this.promise) {
      throw new Error('Must return a promise from "run()" method.')
    }
    if (typeof this.promise.cancel !== 'function') {
      throw new Error('Promise returned from "run()" missing cancel method. Are you importing bluebird?')
    }
    return this.promise
  }

  /**
   * This method should not be overridden.
   * Does validation to check if the promise needs to be cancelled.
   * Runs `cancel` method.
   */
  [cancel] () {
    if (!this.promise) {
      return
    }
    // We don't want to cancel promises that are fulfilled, rejected or cancelled.
    if (typeof this.promise.isPending === 'function' && !this.promise.isPending()) {
      return
    }
    return this.cancel(this.promise)
  }

  /**
   * Runs a command returning a cancellable promise.
   * `CinematicRunner` waits until this Promise has resolved or rejected before moving on.
   *
   * This promise should be a `bluebird` promise and implement a `cancel` method.
   * If you need cleanup behavior in the case of cancellation, you should also override the
   * `cancel` method.
   *
   * @returns {Promise} - The promise that signifies command completion.
   */
  run () {
    throw new Error('You must implement the `run` method.')
  }

  /**
   * Override to change cancellation behavior or add cleanup logic.
   * Must return a promise if cleanup takes time.
   *
   * @param {Promise} promise - The promise returned from the `run` method.
   */
  cancel (promise) {
    promise.cancel()
    return Promise.resolve()
  }
}
