#import "AppDelegate.h"

@interface NSURLRequest (AllowAnyHTTPSCertificate)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host;

@end
