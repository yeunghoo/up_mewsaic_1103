#import <Foundation/Foundation.h>
@class MCGameSession;
#if DEBUG
@interface MCDebugPreview : NSObject
+ (NSInteger)configure:(MCGameSession *)session;
@end
#endif
