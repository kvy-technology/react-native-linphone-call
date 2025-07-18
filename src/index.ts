import { RemoteVideoSurfaceView } from './RemoteVideoSurfaceManager';
export { RemoteVideoSurfaceView };
export { SIPProvider, useSIP } from './provider';
export {
  useCall,
  useAudioDevices,
  useMicrophone,
  useStaticImage,
  DtmfChar,
  StaticImageConfig,
  initialise,
  unregister,
  login,
  acceptCall,
  hangup,
  hasActiveCall
} from './native-wrapper';
