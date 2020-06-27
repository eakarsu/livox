//
//  ServiceClient.h
//  Livo
//
//  Created by Deniz Acay on 31/07/15.
//  Copyright (c) 2015 Livo Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "authc.h"
#import "file.h"
#import "provision.h"
#import "analytic.h"
#import "serviceobj.h"

#import <thrift/TSocketClient.h>
#import <thrift/TFramedTransport.h>
#import <thrift/TBinaryProtocol.h>
#import <thrift/TMultiplexedProtocol.h>

@interface ServiceClient : NSObject

@property (strong,readonly) NSString *serverHost;
@property (strong,readonly) NSNumber *serverPort;

- (instancetype)initWithServerHost:(NSString *)serverHost serverPort:(NSNumber *)serverPort;

#pragma mark - Authentication

- (void)authenticateCompany:(NSString *)companyId companySecret:(NSString *)companySecret success:(void (^)(AuthenticationToken *token))success error:(void (^)(NSString *message))error;
- (void)authenticateUser:(AuthenticationToken *)token userPrincipal:(NSString *)userPrincipal userCredentials:(NSString *)userCredentials success:(void (^)(AuthenticationToken *token))success error:(void (^)(NSString *message))error;
- (void)authenticateDevice:(AuthenticationToken *)token deviceId:(NSString *)deviceId success:(void (^)(AuthenticationToken *token))success error:(void (^)(NSString *message))error;


#pragma mark - Update

- (void)checkProvision:(AuthenticationToken *)token applicationId:(NSString *)applicationId localProfile:(Profile *)localProfile success:(void (^)(Profile *profile))success error:(void (^)(NSString *message))error;
- (FileTransferSession *)initiateSession:(File *)file bucketSize:(int64_t)bucketSize;
- (NSData *)fetchBucket:(FileTransferSession *)session;
- (void)destroySession:(FileTransferSession *)session;


#pragma mark - Analytics

- (BOOL)isOptedIn:(AuthenticationToken *)token;


#pragma mark - ServiceObjects

- (NSSet *)listServiceObjects:(AuthenticationToken *)token;
- (ServiceObject *)getServiceObject:(AuthenticationToken *)token name:(NSString *)name configuration:(NSDictionary *)configuration;
- (ServiceObjectOperationPayload *)performOperation:(AuthenticationToken *)token object:(ServiceObject *)object operationName:(NSString *)operationName payload:(ServiceObjectOperationPayload *)payload;

@end
