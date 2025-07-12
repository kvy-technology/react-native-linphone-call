import linphonesw
import AVFoundation
import React

@objc(Sip)
class Sip: RCTEventEmitter {
    private var mCore: Core!
    private var mRegistrationDelegate : CoreDelegate!
    
    private var bluetoothMic: AudioDevice?
    private var bluetoothSpeaker: AudioDevice?
    private var earpiece: AudioDevice?
    private var loudMic: AudioDevice?
    private var loudSpeaker: AudioDevice?
    private var microphone: AudioDevice?
    private var incomingCallData: (core: Core, call: Call, state: Call.State)?

    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    func configureAudioSessionSpeaker() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth,.defaultToSpeaker])
            try audioSession.setPreferredSampleRate(48000.0)
            try audioSession.setPreferredIOBufferDuration(0.02) // Increase buffer duration to 20ms
            try audioSession.setActive(true)
            print("Audio session configured with sample rate: \(audioSession.sampleRate) and buffer duration: \(audioSession.ioBufferDuration)")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
            try audioSession.setPreferredSampleRate(48000.0)
            try audioSession.setPreferredIOBufferDuration(0.02) // Increase buffer duration to 20ms
            try audioSession.setActive(true)
            print("Audio session configured with sample rate: \(audioSession.sampleRate) and buffer duration: \(audioSession.ioBufferDuration)")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

     // UPDATED - New method
    @objc(setUpVideoView:withRejecter:)
    func setUpVideoView(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        NSLog("[SIP] Trying to setup capture/video view")

        if(RemoteVideoSurface.nativeVideoWindow != nil) {
            let enableVideo: UInt8 = 1

            linphone_core_enable_video_capture(mCore.getCobject, enableVideo);
            linphone_core_enable_video_display(mCore.getCobject, enableVideo)
        
            // Set native window
            mCore.nativeVideoWindow = RemoteVideoSurface.nativeVideoWindow

            resolve(true)
        }
        else {
            reject("Setup video view error", "Can not setup view", nil)
        }
    }
    
    @objc func delete() {
        // To completely remove an Account
        if let account = mCore.defaultAccount {
            mCore.removeAccount(account: account)
            
            // To remove all accounts use
            mCore.clearAccounts()
            
            // Same for auth info
            mCore.clearAllAuthInfo()
        }}
    
    @objc func sendEvent( eventName: String ) {
        self.sendEvent(withName:eventName, body:"");
    }
        
    @objc(initialise:withRejecter:)
    func initialise(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        do {
            LoggingService.Instance.logLevel = LogLevel.Debug
            
            mCore = try Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
            try mCore.start()
            
            // Create a Core listener to listen for the callback we need
            // In this case, we want to know about the account registration status
            mRegistrationDelegate = CoreDelegateStub(
                onCallStateChanged: { (core: Core, call: Call, state: Call.State?, message: String) in
                    guard let state = state else { return }
                    NSLog("[SIP] Call state changed to: \(String(describing: state))")

                    do {
                        switch state {
                        case .IncomingReceived:
                            self.incomingCallData = (core, call, state)
                            self.sendEvent(eventName: "CallRinging")

                        case .OutgoingInit:
                            self.sendEvent(eventName: "ConnectionRequested")
                            
                        case .OutgoingProgress:
                            self.sendEvent(eventName: "CallRequested")
                            
                        case .OutgoingRinging:
                            self.sendEvent(eventName: "CallRinging")
                            
                        case .Connected:
                            self.sendEvent(eventName: "CallConnected")
                            
                        case .StreamsRunning:
                            self.sendEvent(eventName: "CallStreamsRunning")

                        case .Paused:
                            self.sendEvent(eventName: "CallPaused")
                            
                        case .PausedByRemote:
                            self.sendEvent(eventName: "CallPausedByRemote")
                            
                        case .Updating:
                            self.sendEvent(eventName: "CallUpdating")
                            
                        case .UpdatedByRemote:
                            self.sendEvent(eventName: "CallUpdatedByRemote")
                            
                        case .Released:
                            self.incomingCallData = nil
                            self.sendEvent(eventName: "CallReleased")
                            
                        case .Error:
                            NSLog("[SIP] Call Error: \(message)")
                            self.sendEvent(eventName: "CallError")
                            
                        default:
                            NSLog("[SIP] Unhandled call state: \(String(describing: state))")
                        }
                    } catch {
                        NSLog("[SIP] Error handling call state for \(state): \(error.localizedDescription)")
                    }
                },
                onAudioDevicesListUpdated: { (core: Core) in
                    self.sendEvent(eventName: "AudioDevicesChanged")
                }
            )
            
            mCore.addDelegate(delegate: mRegistrationDelegate)

            // let videoActivationPolicy = try Factory.Instance.createVideoActivationPolicy()
            // Enable video call for outgoing call
            // videoActivationPolicy.automaticallyInitiate = true
            // Enable video call for receive call
            // videoActivationPolicy.automaticallyAccept = true
            // mCore.videoActivationPolicy = videoActivationPolicy

            NSLog("[SIP] Initialise success")
         
            resolve(true)
        } catch {
            reject("Initialization Failure", "Failed to initialize core", error)
        }
    }

    @objc(login:withPassword:withDomain:withResolver:withRejecter:)
    func login(username: String, password: String, domain: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        do {
            let transport = TransportType.Tcp
            
            // To configure a SIP account, we need an Account object and an AuthInfo object
            // The first one is how to connect to the proxy server, the second one stores the credentials
            
            // The auth info can be created from the Factory as it's only a data class
            // userID is set to null as it's the same as the username in our case
            // ha1 is set to null as we are using the clear text password. Upon first register, the hash will be computed automatically.
            // The realm will be determined automatically from the first register, as well as the algorithm
            let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: "", passwd: password, ha1: "", realm: "", domain: domain)
            
            // Account object replaces deprecated ProxyConfig object
            // Account object is configured through an AccountParams object that we can obtain from the Core
            let accountParams = try mCore.createAccountParams()
            
            // A SIP account is identified by an identity address that we can construct from the username and domain
            let identity = try Factory.Instance.createAddress(addr: String("sip:" + username + "@" + domain))
            try! accountParams.setIdentityaddress(newValue: identity)
            
            // We also need to configure where the proxy server is located
            let address = try Factory.Instance.createAddress(addr: String("sip:" + domain))
            
            // We use the Address object to easily set the transport protocol
            try address.setTransport(newValue: transport)
            try accountParams.setServeraddress(newValue: address)
            // And we ensure the account will start the registration process
            accountParams.registerEnabled = true
            
            // Now that our AccountParams is configured, we can create the Account object
            let account = try mCore.createAccount(params: accountParams)
            
            // Now let's add our objects to the Core
            mCore.addAuthInfo(info: authInfo)
            try mCore.addAccount(account: account)
            
            // Also set the newly added account as default
            mCore.defaultAccount = account

            NSLog("[SIP] Login success")
            
            resolve(nil)
            
        } catch { NSLog(error.localizedDescription)
            NSLog("[SIP] Login failed")

            reject("Login error", "Could not log in", error)
        }
    }

    @objc(acceptCall:withRejecter:)
    func acceptCall(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        do {
            if let callData = incomingCallData {
                let params = try callData.core.createCallParams(call: callData.call)
                params.videoEnabled = true
                params.videoDirection = .SendRecv
                try callData.call.acceptWithParams(params: params)

                NSLog("[SIP] Accept success")
                resolve(true)
            } else {
                NSLog("[SIP] No call to accept")
                reject("No call", "No call to accept", nil)
            }
        } catch {
            NSLog("[SIP] Accept failed")
            reject("Accept call failed", error.localizedDescription, error)
        }
    }
    
    @objc
    override func supportedEvents() -> [String]! {
        return ["ConnectionRequested", "CallRequested", "CallRinging", "CallConnected", "CallStreamsRunning", "CallPaused", "CallPausedByRemote", "CallUpdating", "CallUpdatedByRemote", "CallReleased", "CallError", "AudioDevicesChanged"]
    }
    
    @objc(unregister:withRejecter:)
    func unregister(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock)
    {
        NSLog("[SIP] Trying to unregister")

        guard let core = mCore else {
            NSLog("[SIP] Unregister failed")
            reject("[SIP] No core", "Unregister failed", nil)
            return
        }
        
        mCore.clearAccounts()
        mCore.clearAllAuthInfo()
        
        // Stop the core in main queue
        // If not, we can got SIGNAL ABRT error
        if Thread.isMainThread {
            self.mCore.stop()
        } else {
            DispatchQueue.main.sync {
                self.mCore.stop()
            }
        }

        NSLog("[SIP] Unregister success")

        resolve(true)
    }
    
    @objc(hangUp:withRejecter:)
    func hangUp(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let core = mCore else {
            reject("No core", "Core not initialized", nil)
            return
        }
    
        NSLog("[SIP] Trying to hang up")
        do {
            if (mCore.callsNb == 0) { return }
            
            // If the call state isn't paused, we can get it using core.currentCall
            let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
            
            // Terminating a call is quite simple
            if let call = coreCall {
                if Thread.isMainThread {
                    do {
                        try call.terminate()
                    } catch {
                        reject("Decline Error", error.localizedDescription, nil)
                    }
                } else {
                    DispatchQueue.main.sync {
                        do {
                            try call.terminate()
                        } catch {
                            reject("Decline Error", error.localizedDescription, nil)
                        }
                    }
                }
            } else {
                reject("No call", "No call to terminate", nil)
            }
        } catch {
            NSLog(error.localizedDescription)
            reject("Call termination failed", "Call termination failed", error)
            
        }
    }
    
    @objc(micEnabled:withRejecter:)
    func micEnabled(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(mCore.micEnabled)
    }
    
    @objc(outgoingCall:withResolver:withRejecter:)
    func outgoingCall(recipient: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        do {
            // As for everything we need to get the SIP URI of the remote and convert it to an Address
            let remoteAddress = try Factory.Instance.createAddress(addr: recipient)
            
            // We also need a CallParams object
            // Create call params expects a Call object for incoming calls, but for outgoing we must use null safely
            let params = try mCore.createCallParams(call: nil)
            
            // We can now configure it
            // Here we ask for no encryption but we could ask for ZRTP/SRTP/DTLS
            params.mediaEncryption = MediaEncryption.SRTP
            // If we wanted to start the call with video directly
            params.videoEnabled = true
            
            // Finally we start the call
            let _ = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
            // Call process can be followed in onCallStateChanged callback from core listener
            resolve(nil)
        } catch { NSLog(error.localizedDescription)
            reject("Outgoing call failure", "Something has gone wrong", error)
        }
    }
    
    
    @objc(bluetoothAudio:withRejecter:)
    func bluetoothAudio(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        if let mic = self.bluetoothMic {
            mCore.inputAudioDevice = mic
        }
        
        if let speaker = self.bluetoothSpeaker {
            mCore.outputAudioDevice = speaker
        }
        
        resolve(true)
    }

    @objc(phoneAudio:withRejecter:)
    func phoneAudio(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        if let mic = microphone {
            mCore.inputAudioDevice = mic
        }

        configureAudioSession()
        resolve(true)
    }

    @objc(loudAudio:withRejecter:)
    func loudAudio(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        if let mic = loudMic {
            mCore.inputAudioDevice = mic
        } else if let mic = self.microphone {
            mCore.inputAudioDevice = mic
        }

        configureAudioSessionSpeaker()
        resolve(true)
    }

    @objc(scanAudioDevices:withRejecter:)
    func scanAudioDevices(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        microphone = nil
        earpiece = nil
        loudSpeaker = nil
        loudMic = nil
        bluetoothSpeaker = nil
        bluetoothMic = nil
        
        for audioDevice in mCore.audioDevices {
            switch (audioDevice.type) {
            case .Microphone:
                microphone = audioDevice
            case .Earpiece:
                earpiece = audioDevice
            case .Speaker:
                if (audioDevice.hasCapability(capability: AudioDevice.Capabilities.CapabilityPlay)) {
                    loudSpeaker = audioDevice
                } else {
                    loudMic = audioDevice
                }
            case .Bluetooth:
                if (audioDevice.hasCapability(capability: AudioDevice.Capabilities.CapabilityPlay)) {
                    bluetoothSpeaker = audioDevice
                } else {
                    bluetoothMic = audioDevice
                }
            default:
                NSLog("[SIP] Audio device not recognised.")
            }
        }
        
        let options: NSDictionary = [
            "phone": microphone != nil,
            "bluetooth": bluetoothMic != nil || bluetoothSpeaker != nil,
            "loudspeaker": loudSpeaker != nil
        ]
        
        var current = "phone"
        if (mCore.outputAudioDevice?.type == .Bluetooth || mCore.inputAudioDevice?.type == .Bluetooth) {
            current = "bluetooth"
        } else if (mCore.outputAudioDevice?.type == .Speaker) {
            current = "loudspeaker"
        }
        
        let result: NSDictionary = [
            "current": current,
            "options": options
        ]
        resolve(result)
    }
    
    @objc(sendDtmf:withResolver:withRejecter:)
    func sendDtmf(dtmf: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        do {
            try mCore.currentCall?.sendDtmf(dtmf: dtmf.utf8CString[0])
            resolve(true) } catch {
                reject("DTMF not recognised", "DTMF not recognised", error)
            }
    }
    
    @objc(toggleMute:withRejecter:)
    func toggleMute(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        mCore.micEnabled = !mCore.micEnabled
        resolve(mCore.micEnabled)
    }
    
    @objc(hasActiveCall:withRejecter:)
    func hasActiveCall(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let core = mCore else {
            resolve(false)
            return
        }

        if let currentCall = core.currentCall {
            // Check for connected/active states
            let isConnected = currentCall.state == .Connected || 
                            currentCall.state == .StreamsRunning
            resolve(isConnected)
            return
        }

        resolve(false)
    }
}
