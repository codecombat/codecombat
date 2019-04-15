import * as Promise from 'bluebird'

Promise.config({
  cancellation: true
})

/**
 * These symbols can be exported in order to call the protected AbstractCommand methods.
 */
export const run = Symbol('private run method')
export const cancel = Symbol('cancellation symbol')

/**
 * AbstractCommand is the abstract base class for objects that will be run in the
 * CommandRunner.
 *
 * This class allows various levels of complexity to be implemented. Most importantly
 * you cannot use this class directly. You must extend this class and at a minimum
 * implment your own `run` method.
 *
 * This method **must** return a **cancellable** promise.
 * I recommend using bluebird although you could likely implemt your own `.cancel` method if you like.
 *
 * Your command is then called via two methods with symbol names. This is to discourage
 * overwriting their implementation.
 * @abstract
 */
export default class AbstractCommand {
  constructor () {
    if (this.constructor === AbstractCommand) {
      throw new Error('This is an abstract class that you must extend.')
    }
  }

  /**
   * This method should not be overriden.
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
   * This method should not be overriden.
   * Runs the `cancel` method passing in the promise returned from `run`.
   * The default implementation of the cancel method calls the cancel method on 
   * the Promise.
   */
  [cancel] () {
    if (!this.promise) {
      return
    }
    if (this.promise.isFulfilled()) {
      return
    }
    return this.cancel(this.promise)
  }

  /**
   * Starts some command that returns a promise.
   * Cinematic runner waits until this Promise has resolved or rejected before moving on.
   * This promise should be a `bluebird` promise and implement a `cancel` method.
   * @returns {Promise} - The promise which completes after command is completed.
   */
  run () {
    throw new Error('You must implement the `run` method.')
  }

  /**
   * Method that you can override to change cancellable behaviour.
   * Should always return a promise.
   * @param {Promise} promise - The promise returned from the `run` method.
   */
  cancel (promise) {
    promise.cancel()
  }
}

export class Noop extends AbstractCommand {
  run () {
    return Promise.resolve()
  }
}
