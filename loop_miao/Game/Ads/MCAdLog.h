#import <Foundation/Foundation.h>

/// Chinese lifecycle diagnostics. Never logs IDFA, consent strings or ad payloads.
FOUNDATION_EXPORT void MCAdLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
