import SwiftUI
import React
import Foundation

@objc(RemoteVideoSurfaceManager)
class RemoteVideoSurfaceManager : RCTViewManager {
  override class func requiresMainQueueSetup() -> Bool {
    return true
  }

  override func view() -> UIView! {
    let contentView = RemoteVideoSurface()

    return UIHostingController(rootView: contentView).view
  }
}
