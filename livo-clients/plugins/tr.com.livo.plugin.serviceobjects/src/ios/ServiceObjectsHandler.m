#import "ServiceObjectsHandler.h"

@interface ServiceObjectsHandler ()

- (id)convertToJavascriptServiceObject:(ServiceObject *)serviceObj;

@end

@implementation ServiceObjectsHandler

- (void)listServiceObjects:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        
        // Get the saved authentication token if any.
        AuthenticationToken *token = [[NSUserDefaults standardUserDefaults] objectForKey:ConfigurationKeyAuthenticationToken] == nil ? nil : [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:ConfigurationKeyAuthenticationToken]];
        
        // Check the authentication token.
        if (token == nil)
        {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Client is not authenticated.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        if (token.isExpired)
        {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Authentication token is expired.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        
        // Get the service objects list.
        NSMutableSet *serviceObjs;
        @try {
            
            // Create an error variable.
            NSError *error;
            
            // Call the service.
            serviceObjs = [[ServiceHelper serviceObjectProxyServiceClient] listServiceObjects:token];
            
            // Create an array for the results.
            NSMutableArray *results = [NSMutableArray array];
            
            // Iterate through the resulting service objects.
            for (ServiceObject *serviceObj in serviceObjs) {
                
                // Create a dictionary for the dummy service object.
                NSMutableDictionary *serviceObjDict = [NSMutableDictionary dictionary];
                
                // Fill the properties.
                [serviceObjDict setObject:serviceObj.name forKey:SERVICE_OBJECT_NAME_PROPERTY];
                [serviceObjDict setObject:serviceObj.type forKey:SERVICE_OBJECT_TYPE_PROPERTY];
                [serviceObjDict setObject:[serviceObj.operationNames allObjects] forKey:SERVICE_OBJECT_OPERATION_NAMES_PROPERTY];
                
                // Add the dictionary to the results.
                [results addObject:serviceObjDict];
                
                // Check for error.
                if (error != nil) {
                    
                    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];

                    return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                }
            }
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:results];

            // Check for error.
            if (error != nil) {
                
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];

                return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }

            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        @catch (NSException *exception) {
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.description];

            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}

- (void)getServiceObject:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        
        // Get the saved authentication token if any.
        AuthenticationToken *token = [[NSUserDefaults standardUserDefaults] objectForKey:ConfigurationKeyAuthenticationToken] == nil ? nil : [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:ConfigurationKeyAuthenticationToken]];
        
        // Check the authentication token.
        if (token == nil)
        {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Client is not authenticated.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        if (token.isExpired)
        {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Authentication token is expired.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        
        // Get the function parameters.
        NSString *serviceObjName = [command argumentAtIndex:0];
        NSDictionary *config = [command argumentAtIndex:1];
        
        // Sanity check for service object name.
        if (serviceObjName == nil || serviceObjName.length == 0) {
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"A ServiceObject instance or a ServiceObject name is required.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        
        // Sanity check for configuration.
        if (config == nil) {
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Configuration required.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        
        // Get the service objects list.
        @try {
            
            // Create an error variable.
            NSError *error;
            
            // Call the service.
            ServiceObject *serviceObj = [[ServiceHelper serviceObjectProxyServiceClient] getServiceObject:token name:serviceObjName conf:config];
            
            // Create a dictionary for the dummy service object.
            NSMutableDictionary *serviceObjDict = [NSMutableDictionary dictionary];
            
            // Fill the properties.
            [serviceObjDict setObject:serviceObj.name forKey:SERVICE_OBJECT_NAME_PROPERTY];
            [serviceObjDict setObject:serviceObj.type forKey:SERVICE_OBJECT_TYPE_PROPERTY];
            [serviceObjDict setObject:[serviceObj.operationNames allObjects] forKey:SERVICE_OBJECT_OPERATION_NAMES_PROPERTY];
            
            // Check for error.
            if (error != nil) {
                
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                
                return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:serviceObjDict];
            
            // Check for error.
            if (error != nil) {
                
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                
                return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
            
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        @catch (NSException *exception) {
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.description];
            
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}

- (void)performOperation:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        
        // Get the saved authentication token if any.
        AuthenticationToken *token = [[NSUserDefaults standardUserDefaults] objectForKey:ConfigurationKeyAuthenticationToken] == nil ? nil : [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:ConfigurationKeyAuthenticationToken]];
        
        // Check the authentication token.
        if (token == nil)
        {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Client is not authenticated.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        if (token.isExpired)
        {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Authentication token is expired.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        
        // Create an error variable.
        NSError *error;
        
        // Get the function parameters.
        NSDictionary *serviceObjDict = [command argumentAtIndex:0];
        NSString *operationName = [command argumentAtIndex:1];
        NSString *payloadString = [command argumentAtIndex:2 withDefault:@"{}"];
        
        // Sanity check for ServiceObject dictionary instance.
        if (serviceObjDict == nil) {
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"A ServiceObject instance to perform the operation on is needed.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        
        // Sanity check for operation name.
        if (operationName == nil || operationName.length == 0) {
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Operation is unknown.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        
        // Sanity check for payload.
        [NSJSONSerialization JSONObjectWithData:[payloadString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (error != nil) {
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NSLocalizedString(@"Payload is malformed.", nil)];
            
            return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        
        // Get the service objects list.
        @try {
            
            // Create the ServiceObject to call the service.
            ServiceObject *serviceObj = [[ServiceObject alloc] initWithName:[serviceObjDict objectForKey:@"name"] type:[serviceObjDict objectForKey:@"type"] operationNames:[NSMutableSet set]];
            
            // Create the payload to send.
            ServiceObjectOperationPayload *payload = [[ServiceObjectOperationPayload alloc] initWithContent:payloadString contentType:@"application/json" rootElement:nil];
            
            // Call the service.
            ServiceObjectOperationPayload *resultPayload = [[ServiceHelper serviceObjectProxyServiceClient] performOperation:token object:serviceObj operationName:operationName payload:payload];
            
            // Parse the result payload.
            NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:[resultPayload.content dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultDict];
            
            // Check for error.
            if (error != nil) {
                
                CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                
                return [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
            
	            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
        @catch (NSException *exception) {
            
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.description];
            
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}

- (id)convertToJavascriptServiceObject:(ServiceObject *)serviceObj
{
    NSAssert(serviceObj != nil, @"Service object to convert is nil!");
    
    return serviceObj.name;
}

@end
