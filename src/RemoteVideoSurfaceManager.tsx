import React,{useEffect} from 'react'
import { requireNativeComponent, ViewProps, HostComponent , Platform} from 'react-native';
import {useCall} from './native-wrapper'

interface Props extends ViewProps {

}


const RemoteVideoSurface: HostComponent<Props> =
  requireNativeComponent('RemoteVideoSurface');

export const RemoteVideoSurfaceView= (props:Props) => {

  const { setUpVideoView } = useCall();

  const waitVideoView = async () => {
    let videoViewReady = false
    while(!videoViewReady) {
      videoViewReady = await setUpVideoView().catch(e=>false);
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }

  useEffect(()=>{
    waitVideoView();
  },[])


  return <RemoteVideoSurface {...props} />;
}


