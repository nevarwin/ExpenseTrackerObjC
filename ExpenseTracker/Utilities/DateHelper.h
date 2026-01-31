#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DateHelper : NSObject

+ (NSInteger)weekIndexForTodayInMonth:(NSInteger)month year:(NSInteger)year;

@end

NS_ASSUME_NONNULL_END
