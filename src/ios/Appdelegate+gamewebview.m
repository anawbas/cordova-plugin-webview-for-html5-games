#import "AppDelegate+gamewebview.h"

@implementation NSURLRequest (AllowAnyHTTPSCertificate)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
    // NSLog(@"Allowing any HTTPS Certificate for host \"%@\"", host);
    return YES;
}

@end
