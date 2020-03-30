import { getCamera, CAMERA_DEFAULT, getSpeaker } from '../../../app/schemas/models/selectors/cinematic'
import { SyncFunction } from './commands/commands'
import { LEFT_SPEAKER_CAMERA_POS, RIGHT_SPEAKER_CAMERA_POS } from './constants'

/**
 * Thin wrapper on the camera to provide additional command methods.
 */
export class CameraSystem {
  constructor (camera) {
    this.camera = camera
    const { pos: { x, y }, zoom } = CAMERA_DEFAULT()
    this.lastCameraMove = { pos: { x, y }, zoom }
    this.camera.zoomTo({ x, y }, zoom, 0)
  }

  zoomToCommand ({ x, y }, zoom) {
    this.lastCameraMove = { pos: { x, y }, zoom }
    return new SyncFunction(() => this.camera.zoomTo({ x, y }, zoom, 0))
  }

  /**
   * May return command to reposition camera.
   * @param {Shot} shot - the cinematic shot data.
   * @returns {AbstractCommand[]} An array of commands to setup the shot.
   */
  parseSetupShot (shot) {
    const commands = []
    const cameraMove = getCamera(shot)
    if (cameraMove) {
      const { pos: { x, y }, zoom } = cameraMove
      commands.push(this.zoomToCommand({ x, y }, zoom))
    }
    return commands
  }

  parseDialogNode (dialogNode) {
    const commands = []
    // Take a good guess at setting the camera to a reasonable default
    // if it hasn't been set. We only set defaults for a zoom of 2.
    if (this.lastCameraMove.zoom !== 2) {
      return commands
    }
    if (this.lastCameraMove.pos.x !== 0 || this.lastCameraMove.pos.y !== 0) {
      return commands
    }
    const speaker = getSpeaker(dialogNode)
    if (speaker === 'left') {
      commands.push(this.zoomToCommand(LEFT_SPEAKER_CAMERA_POS, 2))
    } else if (speaker === 'right') {
      commands.push(this.zoomToCommand(RIGHT_SPEAKER_CAMERA_POS, 2))
    }
    return commands
  }

  destroy () {
    this.camera.destroy()
  }
}
