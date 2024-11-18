import React from 'react';
import * as NativeWrapper from './native-wrapper';

interface SIPOperations {
  login: typeof NativeWrapper.login;
  acceptCall: typeof NativeWrapper.acceptCall;
}

const SIPContext = React.createContext<SIPOperations>({
  login: async () => undefined,
  acceptCall: async () => undefined,
});

interface SIPProviderProps {
  children?: React.ReactNode;
  remoteVideoIdRef?: any;
}
export function SIPProvider({ children = <></> }: SIPProviderProps) {
  const [initialized, setInitialized] = React.useState(false);

  React.useEffect(() => {
    NativeWrapper.Sip.initialise().then(() => setInitialized(true));

    return () => NativeWrapper.Sip.unregister().then(() => setInitialized(false));
  }, []);

  const sipOperations = {
    login: NativeWrapper.login,
    acceptCall: NativeWrapper.acceptCall,
  };

  return initialized ? (
    <SIPContext.Provider value={sipOperations}>{children}</SIPContext.Provider>
  ) : (
    <></>
  );
}

export const useSIP = () => React.useContext(SIPContext);
