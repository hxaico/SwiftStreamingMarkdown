#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Catches Objective-C exceptions thrown by iosMath during LaTeX
/// typesetting so they don't crash the Swift process.
@interface MathExceptionCatcher : NSObject

/// Executes `block`. Returns YES on success.
/// If an ObjC exception is thrown, returns NO and populates `error`.
+ (BOOL)tryBlock:(void (NS_NOESCAPE ^)(void))block
           error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
