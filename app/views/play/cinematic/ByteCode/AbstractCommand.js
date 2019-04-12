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
 * BytecodeThunkRunner.
 *
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
  async [run] () {
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
   * Cancel runs the `preCancel()` method and then cancels the promise
   * that originated from `run()`.
   */
  async [cancel] () {
    if (!this.promise) {
      return
    }
    if (this.promise.isFulfilled()) {
      return
    }
    if (this.preCancel() === 'cancel') {
      return
    }

    this.promise.cancel()

    await this.afterCancel()
  }

  /**
   * Starts some command that returns a promise.
   * Cinematic runner waits until this Promise has resolved or rejected before moving on.
   * This promise should be a `bluebird` promise and implement a `cancel` method.
   * @returns {Promise} - The promise which completes after command is completed.
   */
  async run () {
    throw new Error('You must implement the `run` method.')
  }

  /**
   * Handler that can be implemented for cleaning up after the promise has cancelled.
   */
  async afterCancel () { }

  /**
   * Can do logic prior to cancel happening.
   * @returns {null | string} - Can return the string 'cancel' in order to prevent the promise from being cancelled.
   */
  async preCancel () {
    return true
  }
}

export class Noop extends AbstractCommand {
  async run () {
    return Promise.resolve()
  }
}