/* eslint-env jasmine */
import AbstractCommand, { run, cancel, Noop } from '../../../../app/views/play/cinematic/Command/AbstractCommand'
import * as PromiseBB from 'bluebird'

PromiseBB.config({
  cancellation: true
})

class NaiveExtend extends AbstractCommand {}

class PassInRunCommand extends AbstractCommand {
  constructor (run) {
    super()
    this.run = run
  }
}

describe('AbstractCommand', () => {
  it('abstract class can\'t be constructed', () => {
    expect(() => new AbstractCommand()).toThrow()
  })

  it('constructor works when extended', () => {
    expect(() => new NaiveExtend()).not.toThrow()
  })

  it('run method must be implemented', () => {
    expect(() => (new NaiveExtend()).run()).toThrow()
  })

  it('run must return a promise', () => {
    const invalidRunFunctions = [
      () => undefined,
      () => true,
      () => false,
      () => '',
      () => 'abc',
      () => {},
      () => ({ then: () => { } }), // Fake promise
      () => Promise.resolve() // non cancellable promise
    ]

    for (const fn of invalidRunFunctions) {
      expect(() => (new PassInRunCommand(fn))[run]()).toThrow()
    }
  })
})

describe('Noop command', () => {
  it('doesn\'t throw error when run', () => {
    expect(() => (new Noop())[run]()).not.toThrow()
  })
})
