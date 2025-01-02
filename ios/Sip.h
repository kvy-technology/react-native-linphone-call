#import <React/RCTBridgeModule.h>

@interface Sip : NSObject <RCTBridgeModule>

- (void)initialise:(RCTPromiseResolveBlock)resolve 
      withRejecter:(RCTPromiseRejectBlock)reject;

- (void)login:(NSString *)username 
  withPassword:(NSString *)password 
    withDomain:(NSString *)domain
  withResolver:(RCTPromiseResolveBlock)resolve 
  withRejecter:(RCTPromiseRejectBlock)reject;

- (void)hasActiveCall:(RCTPromiseResolveBlock)resolve 
    withRejecter:(RCTPromiseRejectBlock)reject;

@end
