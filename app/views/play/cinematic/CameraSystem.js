import { getCamera } from '../../../schemas/selectors/cinematic'
import { SyncFunction } from './Command/commands'

/**
 * Thin wrapper on the camera to provide additional command methods.
 */
export class CameraSystem {
  constructor (camera) {
    this.camera = camera
  }

  /**
   * May return command to reposition camera.
   * @param {Shot} shot - the cinematic shot data.
   */
  parseSetupShot (shot) {
    const commands = []
    const cameraMove = getCamera(shot)
    if (cameraMove) {
      const { pos: { x, y }, zoom } = cameraMove
      commands.push(new SyncFunction(() => {
        console.log('camera zooming!')
        this.camera.zoomTo({ x, y }, zoom, 0)
      }))
    }
    return commands
  }
}
