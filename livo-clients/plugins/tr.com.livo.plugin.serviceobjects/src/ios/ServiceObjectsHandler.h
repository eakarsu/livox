#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

#import "ServiceHelper.h"

#define SERVICE_OBJECT_NAME_PROPERTY @"name"
#define SERVICE_OBJECT_TYPE_PROPERTY @"type"
#define SERVICE_OBJECT_OPERATION_NAMES_PROPERTY @"operationNames"

@interface ServiceObjectsHandler : CDVPlugin {
}

- (void)listServiceObjects:(CDVInvokedUrlCommand*)command;
- (void)getServiceObject:(CDVInvokedUrlCommand*)command;
- (void)performOperation:(CDVInvokedUrlCommand*)command;

@end
