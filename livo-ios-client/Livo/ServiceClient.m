//
//  ServiceClient.m
//  Livo
//
//  Created by Deniz Acay on 31/07/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

#import "ServiceClient.h"

@interface ServiceClient ()

@property (strong,nonatomic) TSocketClient *socket;
@property (strong,nonatomic) AuthenticationServiceClient *authenticationServiceClient;
@property (strong,nonatomic) ProvisioningServiceClient *provisioningServiceClient;
@property (strong,nonatomic) FileTransferServiceClient *fileTransferServiceClient;
@property (strong,nonatomic) AnalyticsServiceClient *analyticsServiceClient;
@property (strong,nonatomic) ServiceObjectProxyServiceClient *serviceObjectProxyServiceClient;

- (void)initializeClient;

@end

@implementation ServiceClient

@synthesize serverHost = _serverHost, serverPort = _serverPort, socket, authenticationServiceClient, provisioningServiceClient, fileTransferServiceClient;

- (instancetype)initWithServerHost:(NSString *)serverHost serverPort:(NSNumber *)serverPort
{
    self = [super init];
    if (self) {
        
        // Save the server host and port parameters for properties
        _serverHost = serverHost;
        _serverPort = serverPort;
        
        // Initialize the client
        [self initializeClient];
    }
    return self;
}

- (void)initializeClient {
    
    // Create socket client
    self.socket = [[TSocketClient alloc] initWithHostname:_serverHost port:_serverPort.intValue];
    
    // Create framed transport
    TFramedTransport *transport = [[TFramedTransport alloc] initWithTransport:self.socket];
    
    // Create binary protocol
    TBinaryProtocol *binaryProtocol = [[TBinaryProtocol alloc] initWithTransport:transport strictRead:YES strictWrite:YES];
    
    // Create multiplexed protocols
    TMultiplexedProtocol *authenticationServiceProtocol = [[TMultiplexedProtocol alloc] initWithProtocol:binaryProtocol serviceName:@"AuthenticationService"];
    TMultiplexedProtocol *provisioningServiceProtocol = [[TMultiplexedProtocol alloc] initWithProtocol:binaryProtocol serviceName:@"ProvisioningService"];
    TMultiplexedProtocol *fileTransferServiceProtocol = [[TMultiplexedProtocol alloc] initWithProtocol:binaryProtocol serviceName:@"FileTransferService"];
    TMultiplexedProtocol *analyticsServiceProtocol = [[TMultiplexedProtocol alloc] initWithProtocol:binaryProtocol serviceName:@"AnalyticsService"];
    TMultiplexedProtocol *serviceObjectProxyServiceProtocol = [[TMultiplexedProtocol alloc] initWithProtocol:binaryProtocol serviceName:@"ServiceObjectProxyService"];
    
    // Create clients
    self.authenticationServiceClient = [[AuthenticationServiceClient alloc] initWithProtocol:authenticationServiceProtocol];
    self.provisioningServiceClient = [[ProvisioningServiceClient alloc] initWithProtocol:provisioningServiceProtocol];
    self.fileTransferServiceClient = [[FileTransferServiceClient alloc] initWithProtocol:fileTransferServiceProtocol];
    self.analyticsServiceClient = [[AnalyticsServiceClient alloc] initWithProtocol:analyticsServiceProtocol];
    self.serviceObjectProxyServiceClient = [[ServiceObjectProxyServiceClient alloc] initWithProtocol:serviceObjectProxyServiceProtocol];
    
}

- (void)authenticateCompany:(NSString *)companyId companySecret:(NSString *)companySecret success:(void (^)(AuthenticationToken *))success error:(void (^)(NSString *))error {
    
    @try {
        
        CompanyAuthenticationResult *result = [self.authenticationServiceClient authenticateCompany:companyId companySecret:companySecret];
        
        if (result.success) {
            
            success(result.authenticationToken);
            
        } else {
            
            error(result.message == nil ? NSLocalizedString(@"Authentication failed for an unknown reason.", nil) : result.message);
        }
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to perform company-level authentication.");
        NSLog(@"%@", exception);
        
        error(NSLocalizedString(@"Authentication failed for an unknown reason.", nil));
    }
}

- (void)authenticateUser:(AuthenticationToken *)token userPrincipal:(NSString *)userPrincipal userCredentials:(NSString *)userCredentials success:(void (^)(AuthenticationToken *))success error:(void (^)(NSString *))error {
    
    @try {
        
        UserAuthenticationResult *result = [self.authenticationServiceClient authenticateUser:token userPrincipal:userPrincipal userCredentials:userCredentials];
        
        if (result.success) {
            
            success(result.authenticationToken);
            
        } else {
            
            error(result.message == nil ? NSLocalizedString(@"Authentication failed for an unknown reason.", nil) : result.message);
        }
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to perform user-level authentication.");
        NSLog(@"%@", exception);
        
        error(NSLocalizedString(@"Authentication failed for an unknown reason.", nil));
    }
}

- (void)authenticateDevice:(AuthenticationToken *)token deviceId:(NSString *)deviceId success:(void (^)(AuthenticationToken *))success error:(void (^)(NSString *))error {
    
    @try {
        
        DeviceAuthenticationResult *result = [self.authenticationServiceClient authenticateDevice:token deviceId:deviceId];
        
        if (result.success) {
            
            success(result.authenticationToken);
            
        } else {
            
            error(result.message == nil ? NSLocalizedString(@"Authentication failed for an unknown reason.", nil) : result.message);
        }
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to perform device-level authentication.");
        NSLog(@"%@", exception);
        
        error(NSLocalizedString(@"Authentication failed for an unknown reason.", nil));
    }
}

- (void)checkProvision:(AuthenticationToken *)token applicationId:(NSString *)applicationId localProfile:(Profile *)localProfile success:(void (^)(Profile *))success error:(void (^)(NSString *))error {
    
    // Consider applicationId too, maybe with a key like applicationId:localProfile
    
    @try {
        
        Profile *remoteProfile = [self.provisioningServiceClient checkProvision:token applicationId:applicationId localProfile:localProfile];
        
        if ([@"" isEqualToString:remoteProfile.hash]) {
            
            NSLog(@"Remote profile is empty.");
            
            // No updates
            remoteProfile = nil;
        }
        
        success(remoteProfile);
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to check for provision.");
        NSLog(@"%@", exception);
        
        error(NSLocalizedString(@"Provision check failed for an unknown reason.", nil));
    }
}

- (FileTransferSession *)initiateSession:(File *)file bucketSize:(int64_t)bucketSize {
    
    @try {
        
        return [self.fileTransferServiceClient initiateSession:file bucketSize:bucketSize];
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to initiate file transfer session.");
        NSLog(@"%@", exception);
        
        return nil;
    }
}

- (void)destroySession:(FileTransferSession *)session {
    
    @try {
        
        [self.fileTransferServiceClient destroySession:session];
        
    } @catch(NSException *exception) {
        
        NSLog(@"Failed to destroy file transfer session.");
        NSLog(@"%@", exception);
    }
}

- (NSData *)fetchBucket:(FileTransferSession *)session {
    
    @try {
        
        return [self.fileTransferServiceClient fetchBucket:session];
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to fetch the bucket %lld of %lld for file '%@'.", session.currentIndex, session.bucketCount, session.file.hash);
        NSLog(@"%@", exception);
        
        return [NSData data];
    }
}

- (BOOL)isOptedIn:(AuthenticationToken *)token {
    
    @try {
        
        return [self.analyticsServiceClient isOptedIn:token];
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to check whether the user with token '%@' is opted in; returning negative answer...", token.uniqueValue);
        NSLog(@"%@", exception);
        
        return NO;
    }
}

- (NSSet *)listServiceObjects:(AuthenticationToken *)token {
    
    @try {
        
        return [self.serviceObjectProxyServiceClient listServiceObjects:token];
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to list service objects for token token '%@'; returning empty set...", token.uniqueValue);
        NSLog(@"%@", exception);
        
        return [NSSet set];
    }
}

- (ServiceObject *)getServiceObject:(AuthenticationToken *)token name:(NSString *)name configuration:(NSDictionary *)configuration {
    
    @try {
        
        return [self.serviceObjectProxyServiceClient getServiceObject:token name:name conf:[NSMutableDictionary dictionaryWithDictionary:configuration]];
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to configure a service object of type '%@' for token '%@'; returning nil...", name, token.uniqueValue);
        NSLog(@"%@", exception);
        
        return nil;
    }
}

- (ServiceObjectOperationPayload *)performOperation:(AuthenticationToken *)token object:(ServiceObject *)object operationName:(NSString *)operationName payload:(ServiceObjectOperationPayload *)payload {
    
    @try {
        
        return [self.serviceObjectProxyServiceClient performOperation:token object:object operationName:operationName payload:payload];
        
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to perform operation '%@' on service object of type '%@' for token '%@'; returning nil...", operationName, object.name, token.uniqueValue);
        NSLog(@"%@", exception);
        
        return nil;
    }
}

@end
