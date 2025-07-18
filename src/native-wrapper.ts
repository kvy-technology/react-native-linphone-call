import { NativeModules, Platform } from 'react-native';
import { NativeEventEmitter } from 'react-native';
import React from 'react';

const LINKING_ERROR =
  `The package 'react-native-sip-phone' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

export const Sip = NativeModules.Sip
  ? NativeModules.Sip
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

interface Callbacks {
  // First state an outgoing call will go through
  onConnectionRequested?: () => void;

  // First state an outgoing call will go through
  onCallRequested?: () => void;

  // Once remote accepts, ringing will commence (180 response)
  onCallRinging?: () => void;
  onCallConnected?: () => void;

  // This state indicates the call is active.
  // You may reach this state multiple times, for example after a pause/resume
  // or after the ICE negotiation completes
  // Wait for the call to be connected before allowing a call update
  onCallStreamsRunning?: () => void;
  onCallPaused?: () => void;
  onCallPausedByRemote?: () => void;

  // When we request a call update, for example when toggling video
  onCallUpdating?: () => void;
  onCallUpdatedByRemote?: () => void;
  onCallReleased?: () => void;
  onCallError?: () => void;
  onLogin?: (username?: string) => void;
  onLogout?: (username: string) => void;
  onAuthenticationError?: (username: string) => void;
}

export function multiply(a: number, b: number): Promise<number> {
  return Sip.multiply(a, b);
}

export function login(
  username: string,
  password: string,
  domain: string
): Promise<void> {
  return Sip.login(username, password, domain);
}

export function acceptCall(
): Promise<void> {
  return Sip.acceptCall();
}

export function initialise(
): Promise<void> {
  return Sip.initialise();
}

export function unregister(
): Promise<void> {
  return Sip.unregister();
}

export function hangup(
): Promise<void> {
  return Sip.hangUp();
}

export function hasActiveCall(): Promise<boolean> {
  return Sip.hasActiveCall();
}

export type DtmfChar =
  | '0'
  | '1'
  | '2'
  | '3'
  | '4'
  | '5'
  | '6'
  | '7'
  | '8'
  | '9'
  | '0'
  | '*'
  | '#';

// Add new interfaces for static image support
export interface StaticImageConfig {
  imagePath: string; // Path to the static image file (required)
  fps?: number;      // Optional: frame rate for static picture (default is usually 1 fps)
}

type SipCall = {
  call: (remoteUri: string) => Promise<void>;
  hangup: () => Promise<void>;
  toggleVideo: () => Promise<void>;
  setUpVideoView: () => Promise<boolean>;
  sendDtmf: (dtmf: DtmfChar) => Promise<void>;
  // Simplified static image functions
  setStaticImage: (config: StaticImageConfig) => Promise<boolean>;
  clearStaticImage: () => Promise<boolean>;
};

export function useCall(callbacks: Callbacks = {}): SipCall {
  React.useEffect(() => {
    const eventEmitter = new NativeEventEmitter(Sip);

    const eventListeners = Object.entries(callbacks).map(
      ([event, callback]) => {
        return eventEmitter.addListener(event.slice(2), callback);
      }
    );
    return () => eventListeners.forEach((listener) => listener.remove());
  }, [callbacks]);

  return {
    call: (remoteUri: string) => Sip.outgoingCall(remoteUri),
    hangup: () => Sip.hangUp(),
    toggleVideo: () => Sip.toggleVideo(),
    setUpVideoView: () => Sip.setUpVideoView(),
    sendDtmf: (dtmf: DtmfChar) => Sip.sendDtmf(dtmf),
    // Simplified static image functions
    setStaticImage: (config: StaticImageConfig) => Sip.setStaticImage(config),
    clearStaticImage: () => Sip.clearStaticImage(),
  };
}

type AudioDevice = 'bluetooth' | 'phone' | 'loudspeaker';

interface AudioDevices {
  options: { [device in AudioDevice]: boolean };
  current: AudioDevice;
}

const initialDevices: AudioDevices = {
  current: 'phone',
  options: {
    bluetooth: false,
    loudspeaker: false,
    phone: true,
  },
};

export function useAudioDevices(): [
  AudioDevices,
  (device: AudioDevice) => Promise<boolean>
] {
  const [current, setCurrent] = React.useState<AudioDevice>(
    initialDevices.current
  );
  const [options, setOptions] = React.useState<{
    [device in AudioDevice]: boolean;
  }>(initialDevices.options);

  const scanAudioDevices = React.useCallback(
    () =>
      Sip.scanAudioDevices().then((audioDevices: AudioDevices) => {
        setCurrent(audioDevices.current);
        setOptions(audioDevices.options);
      }),
    []
  );

  React.useEffect(() => {
    const eventEmitter = new NativeEventEmitter(Sip);

    const deviceListener = eventEmitter.addListener(
      'AudioDevicesChanged',
      scanAudioDevices
    );
    return () => deviceListener.remove();
  }, [scanAudioDevices]);

  React.useEffect(() => {
    scanAudioDevices();
  }, [scanAudioDevices]);

  const switchAudio = React.useCallback(
    async (device: AudioDevice) => {
      if (!options[device]) {
        return false;
      }

      let result: boolean;
      if (device === 'bluetooth') {
        result = await Sip.bluetoothAudio();
      } else if (device === 'loudspeaker') {
        result = await Sip.loudAudio();
      } else if (device === 'phone') {
        result = await Sip.phoneAudio();
      } else {
        result = false;
      }

      if (result) {
        scanAudioDevices();
      }

      return result;
    },
    [options, scanAudioDevices]
  );

  return [{ current, options }, switchAudio];
}

export function useMicrophone(): [boolean, () => Promise<void>] {
  const [micEnabled, setMicEnabled] = React.useState<boolean>(false);

  React.useEffect(() => {
    Sip.micEnabled().then(setMicEnabled);
  }, []);

  const toggle = async () => {
    const newValue = await Sip.toggleMute()

    setMicEnabled(newValue)
  }

  return [micEnabled, toggle];
}

export function useStaticImage(): [
  boolean,
  (config: StaticImageConfig) => Promise<boolean>,
  () => Promise<boolean>
] {
  const [isStaticImageActive, setIsStaticImageActive] = React.useState<boolean>(false);

  const setStaticImage = async (config: StaticImageConfig): Promise<boolean> => {
    try {
      const result = await Sip.setStaticImage(config);
      if (result) {
        setIsStaticImageActive(true);
      }
      return result;
    } catch (error) {
      console.error('Failed to set static image:', error);
      return false;
    }
  };

  const clearStaticImage = async (): Promise<boolean> => {
    try {
      const result = await Sip.clearStaticImage();
      if (result) {
        setIsStaticImageActive(false);
      }
      return result;
    } catch (error) {
      console.error('Failed to clear static image:', error);
      return false;
    }
  };

  return [isStaticImageActive, setStaticImage, clearStaticImage];
}
