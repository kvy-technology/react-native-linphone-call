package com.reactnativesip

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.SimpleViewManager
import android.widget.TextView
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.drawee.backends.pipeline.Fresco
import android.util.Log
import android.os.Bundle
import com.facebook.react.bridge.LifecycleEventListener
import android.graphics.Color
import android.view.ViewGroup
import android.view.View
import com.facebook.react.uimanager.annotations.ReactPropGroup
import com.facebook.react.uimanager.annotations.ReactProp
import android.view.Choreographer
import android.view.LayoutInflater
import com.facebook.react.views.view.ReactViewGroup
import org.linphone.mediastream.video.capture.CaptureTextureView


class RemoteVideoSurfaceManager(private val reactContext: ReactApplicationContext): SimpleViewManager <ReactViewGroup>() {

  override fun getName(): String {
    return TAG
  }

  override fun createViewInstance(context: ThemedReactContext) : ReactViewGroup {

    val videoView: View = LayoutInflater.from(context).inflate(R.layout.incall, null);

    var viewGroup = ReactViewGroup(context)

    viewGroup.addView(videoView)

    setupLayout(viewGroup, videoView)

    return viewGroup
  }

  fun setupLayout(viewGroup: View, videoView: View) {
    Choreographer.getInstance().postFrameCallback(object: Choreographer.FrameCallback {
      override fun doFrame(frameTimeNanos: Long) {
        manuallyLayoutChildren(viewGroup, videoView)
        viewGroup.viewTreeObserver.dispatchOnGlobalLayout()
        Choreographer.getInstance().postFrameCallback(this)
      }
    })
  }

  /**
   * Layout all children properly
   */
  private fun manuallyLayoutChildren(viewGroup: View, videoView: View) {

    val width = viewGroup.width
    val height = viewGroup.height

    videoView.measure(
        View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))

    videoView.layout(0, 0, width, height)
  }

  companion object {
    private const val TAG = "RemoteVideoSurface"
  }
}
