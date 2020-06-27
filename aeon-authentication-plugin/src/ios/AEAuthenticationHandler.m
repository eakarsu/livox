#import "AEAuthenticationHandler.h"

@implementation AEAuthenticationHandler

- (void)authenticateCompany:(CDVInvokedUrlCommand*)command
{

	// Get the company ID and company secret arguments.
	NSString *companyId = [command argumentAtIndex:0];
	NSString *companySecret = [command argumentAtIndex:1];
}

- (void)authenticateUser:(CDVInvokedUrlCommand*)command
{

}

@end
