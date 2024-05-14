import SwiftUI
import linphonesw

struct RemoteVideoSurface: View {
    static var nativeVideoWindow: UIView? = nil;

    var body:some View {
        LinphoneVideoViewHolder() { view in
            print("IntercomSDK: LinphoneVideoViewHolder returned");
            RemoteVideoSurface.nativeVideoWindow = view
        }
    }
}
