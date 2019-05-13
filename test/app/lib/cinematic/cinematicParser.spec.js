/* eslint-env jasmine */
import { parseShot } from '../../../../app/views/play/cinematic/Command/CinematicParser'

describe('parseShot', () => {
  it('handles an empty shot', () => {
    expect(parseShot({})).toEqual([[]])
  })

  it('parses setup correctly', () => {
    const systems = [{
      parseSetupShot: jasmine.createSpy().and.returnValue(['setup commands'])
    }]
    const shot = {
      setupShot: 'Example setup shot'
    }
    const results = parseShot(shot, systems)
    expect(systems[0].parseSetupShot).toHaveBeenCalledWith({ setupShot: 'Example setup shot' })
    expect(results).toEqual([['setup commands']])
  })

  it('parses setup correctly with many systems', () => {
    const systems = [{
      parseSetupShot: jasmine.createSpy().and.returnValue(['setup command1'])
    }, {
      parseSetupShot: jasmine.createSpy().and.returnValue(['setup command2'])
    }]
    const shot = {
      setupShot: 'Example setup shot'
    }
    const results = parseShot(shot, systems)
    expect(systems[0].parseSetupShot).toHaveBeenCalledWith({ setupShot: 'Example setup shot' })
    expect(systems[1].parseSetupShot).toHaveBeenCalledWith({ setupShot: 'Example setup shot' })
    expect(results).toEqual([['setup command1', 'setup command2']])
  })

  it('dialogNode array data passed into parseDialogNode system', () => {
    const systems = [{
      parseDialogNode: jasmine.createSpy().and.returnValue(['dialog commands'])
    }]
    const shot = {
      dialogNodes: ['DialogNode1', 'DialogNode2']
    }
    const results = parseShot(shot, systems)
    expect(systems[0].parseDialogNode.calls.all().map(o => o.args)).toEqual([['DialogNode1'], ['DialogNode2']])
    // I don't like this test but I couldn't figure out another way.
    expect(JSON.stringify(results)).toEqual('[[{"commands":["dialog commands"]}],[{"commands":["dialog commands"]}]]')
  })

  it('correctly attaches setup to first command array', () => {
    const systems = [{
      parseSetupShot: jasmine.createSpy().and.returnValue(['setup commands']),
      parseDialogNode: jasmine.createSpy().and.returnValue(['dialog commands'])
    }]
    const shot = {
      setupShot: 'Example setup shot',
      dialogNodes: ['DialogNode1', 'DialogNode2']
    }

    const results = parseShot(shot, systems)
    expect(systems[0].parseDialogNode.calls.all().map(o => o.args)).toEqual([['DialogNode1'], ['DialogNode2']])
    expect(systems[0].parseSetupShot).toHaveBeenCalledWith(shot)
    expect(JSON.stringify(results)).toEqual('[["setup commands",{"commands":["dialog commands"]}],[{"commands":["dialog commands"]}]]')
  })

  it('parseSetupShot must return array or error is thrown', () => {
    const systems = [{
      parseSetupShot: jasmine.createSpy()
    }]
    const shot = {
      setupShot: 'example setup shot'
    }
    expect(() => parseShot(shot, systems)).toThrow()
  })

  it('parseDialogNode must return array or error is thrown', () => {
    const systems = [{
      parseDialogNode: jasmine.createSpy()
    }]
    const shot = {
      dialogNodes: ['example setup shot']
    }
    expect(() => parseShot(shot, systems)).toThrow()
  })
})
