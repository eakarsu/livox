#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface AEAuthenticationHandler : CDVPlugin {
}

- (void)authenticateCompany:(CDVInvokedUrlCommand*)command;

- (void)authenticateUser:(CDVInvokedUrlCommand*)command;

@end
