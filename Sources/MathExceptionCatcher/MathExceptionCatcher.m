#import "MathExceptionCatcher.h"

@implementation MathExceptionCatcher

+ (BOOL)tryBlock:(void (NS_NOESCAPE ^)(void))block
           error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    @try {
        block();
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.monogram.iosMath"
                                         code:1
                                     userInfo:@{
                NSLocalizedDescriptionKey: exception.reason ?: @"Unknown iosMath exception",
                @"ExceptionName": exception.name ?: @"Unknown"
            }];
        }
        return NO;
    }
}

@end
