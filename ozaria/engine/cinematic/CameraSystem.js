import { getCamera, CAMERA_DEFAULT } from '../../../app/schemas/models/selectors/cinematic'
import { SyncFunction } from './commands/commands'

/**
 * Thin wrapper on the camera to provide additional command methods.
 */
export class CameraSystem {
  constructor (camera) {
    this.camera = camera

    camera.zoomTo({ x: CAMERA_DEFAULT.pos.x, y: CAMERA_DEFAULT.pos.y }, CAMERA_DEFAULT.zoom, 0)
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
      commands.push(new SyncFunction(() => this.camera.zoomTo({ x, y }, zoom, 0)))
    }
    return commands
  }

  destroy () {
    this.camera.destroy()
  }
}
