import React, { useEffect } from 'react';
import { requireNativeComponent, ViewProps, HostComponent } from 'react-native';
import { useCall } from './native-wrapper';

interface Props extends ViewProps {}

const RemoteVideoSurface: HostComponent<Props> =
  requireNativeComponent('RemoteVideoSurface');

export const RemoteVideoSurfaceView = (props: Props) => {
  const { setUpVideoView } = useCall();

  const waitVideoView = async () => {
    let videoViewReady = false;
    while (!videoViewReady) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      videoViewReady = await setUpVideoView().catch(() => false);
    }
  };

  useEffect(() => {
    waitVideoView();
  }, []);

  return <RemoteVideoSurface {...props} />;
};
