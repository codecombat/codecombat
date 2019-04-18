/* eslint-env jasmine */
import CommandRunner from '../../../../app/views/play/cinematic/Command/CommandRunner'
import AbstractCommand from '../../../../app/views/play/cinematic/Command/AbstractCommand'
import Promise from 'bluebird'
const utils = require('../../utils.coffee')

Promise.config({
  cancellation: true
})

const sleep = ms => new Promise((resolve, reject) => setTimeout(resolve, ms))

// Command that we use to test commandRunner functionality.
class SpyCommand extends AbstractCommand {
  constructor (spy, ms) {
    super()
    this.run = () => sleep(ms).then(spy)
  }
}

describe('commandRunner', () => {
  it('runs all commands provided', utils.wrapJasmine(async () => {
    const spy = jasmine.createSpy('commandPromiseSpy')

    const commands = []
    const commandLength = 5 + Math.floor((Math.random() * 10))
    for (let i = 0; i < commandLength; i++) {
      commands.push(new SpyCommand(spy, 100))
    }
    const c = new CommandRunner(commands)
    await c.run()

    expect(spy).toHaveBeenCalledTimes(commandLength)
  }))

  it('cancels commands immediately correctly', utils.wrapJasmine(async () => {
    const spy = jasmine.createSpy('commandPromiseSpy')

    const commands = []
    const commandLength = 1 + Math.floor((Math.random() * 10))
    for (let i = 0; i < commandLength; i++) {
      commands.push(new SpyCommand(spy, 100))
    }
    const c = new CommandRunner(commands)
    c.cancel()
    await c.run()

    expect(spy).not.toHaveBeenCalled()
  }))

  it('can cancel commands midway', utils.wrapJasmine(async () => {
    // In order for this test to not be brittle I've made the sleep delay much longer.
    const spy = jasmine.createSpy('commandPromiseSpy')

    const commands = []
    // There will always be 5 commands. We will cancel after 2.
    const beforeCancel = 2 + Math.floor((Math.random() * 3))
    const afterCancel = 2 + Math.floor((Math.random() * 3))
    const sleepTime = 150
    for (let i = 0; i < (beforeCancel + afterCancel); i++) {
      commands.push(new SpyCommand(spy, sleepTime))
    }
    const c = new CommandRunner(commands)

    sleep((sleepTime * beforeCancel) + (sleepTime / 2)).then(() => c.cancel())
    await c.run()

    expect(spy).toHaveBeenCalledTimes(beforeCancel + 1)
  }))
})
