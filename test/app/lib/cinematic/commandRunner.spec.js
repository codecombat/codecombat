/* eslint-env jasmine */
import CommandRunner from '../../../../ozaria/engine/cinematic/commands/CommandRunner'
import AbstractCommand from '../../../../ozaria/engine/cinematic/commands/AbstractCommand'
import Promise from 'bluebird'
const utils = require('../../utils.coffee')

Promise.config({
  cancellation: true
})

const sleep = ms => new Promise((resolve, reject) => setTimeout(resolve, ms))

// Command that we use to test commandRunner functionality.
class SpyCommand extends AbstractCommand {
  constructor (spyRunner, ms, spyCancel) {
    super()
    this.run = () => sleep(ms).then(spyRunner)

    // We can also spy on cancel calls.
    if (typeof spyCancel === 'function') {
      this.cancel = promise => {
        promise.cancel()
        spyCancel()
        return Promise.resolve()
      }
    }
  }
}

describe('commandRunner', () => {
  it('runs all commands provided', utils.wrapJasmine(async () => {
    const spy = jasmine.createSpy('commandPromiseSpy')
    const cancelSpy = jasmine.createSpy('cancelSpy')

    const commands = []
    const commandLength = 5 + Math.floor((Math.random() * 10))
    for (let i = 0; i < commandLength; i++) {
      commands.push(new SpyCommand(spy, 100, cancelSpy))
    }
    const c = new CommandRunner(commands)
    await c.run()

    expect(spy).toHaveBeenCalledTimes(commandLength)
    expect(cancelSpy).not.toHaveBeenCalled()
  }))

  it('cancels commands immediately correctly', utils.wrapJasmine(async () => {
    const spy = jasmine.createSpy('commandPromiseSpy')
    const cancelSpy = jasmine.createSpy('cancelSpy')

    const commands = []
    const commandLength = 1 + Math.floor((Math.random() * 10))
    for (let i = 0; i < commandLength; i++) {
      commands.push(new SpyCommand(spy, 100, cancelSpy))
    }
    const c = new CommandRunner(commands)
    c.cancel()
    await c.run()

    expect(spy).not.toHaveBeenCalled()
    expect(cancelSpy).toHaveBeenCalledTimes(commandLength)
  }))

  it('can cancel commands midway', utils.wrapJasmine(async () => {
    const spy = jasmine.createSpy('commandPromiseSpy')
    const cancelSpy = jasmine.createSpy('cancelSpy')

    const commands = []

    // Then number of commands before and after the cancellation point.
    const beforeCancel = 2 + Math.floor((Math.random() * 3))
    const afterCancel = 2 + Math.floor((Math.random() * 3))
    const sleepTime = 150
    for (let i = 0; i < (beforeCancel + afterCancel); i++) {
      commands.push(new SpyCommand(spy, sleepTime, cancelSpy))
    }
    const c = new CommandRunner(commands)

    sleep((sleepTime * beforeCancel) + (sleepTime / 2)).then(() => c.cancel())
    await c.run()

    expect(spy).toHaveBeenCalledTimes(beforeCancel)
    expect(cancelSpy).toHaveBeenCalledTimes(afterCancel)
  }))

  it('late cancel doesn\'t disrupt command running', utils.wrapJasmine(async () => {
    const spy = jasmine.createSpy('commandPromiseSpy')
    const cancelSpy = jasmine.createSpy('cancelSpy')

    const commands = []

    const beforeCancel = 2 + Math.floor((Math.random() * 3))
    const sleepTime = 150
    for (let i = 0; i < (beforeCancel); i++) {
      commands.push(new SpyCommand(spy, sleepTime, cancelSpy))
    }
    const c = new CommandRunner(commands)

    sleep((sleepTime * beforeCancel) + (sleepTime / 2)).then(() => c.cancel())
    await c.run()

    expect(spy).toHaveBeenCalledTimes(beforeCancel)
    expect(cancelSpy).not.toHaveBeenCalled()
  }))
})
