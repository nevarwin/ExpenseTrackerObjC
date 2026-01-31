#import "DateHelper.h"

@implementation DateHelper

+ (NSInteger)weekIndexForTodayInMonth:(NSInteger)month year:(NSInteger)year {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.firstWeekday = 2; // Monday
    
    // First day of month
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = 1;
    NSDate *startOfMonth = [calendar dateFromComponents:components];
    
    // Find first Monday *inside* the month
    NSDateComponents *weekdayComponents = [calendar components:NSCalendarUnitWeekday fromDate:startOfMonth];
    NSInteger weekday = weekdayComponents.weekday;
    NSInteger daysToAdd = (weekday == 2) ? 0 : (9 - weekday) % 7;
    NSDate *firstMonday = [calendar dateByAddingUnit:NSCalendarUnitDay
                                               value:daysToAdd
                                              toDate:startOfMonth
                                             options:0];
    
    // Today
    NSDate *today = [NSDate date];
    NSDateComponents *todayComp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:today];
    
    // Only compute if it's the same month & year
    if (todayComp.year == year && todayComp.month == month) {
        NSInteger daysDiff = [calendar components:NSCalendarUnitDay
                                         fromDate:firstMonday
                                           toDate:today
                                          options:0].day;
        if (daysDiff >= 0) {
            return daysDiff / 7; // week index (0-based)
        }
    }
    return 0; // default to week 0 if not current month
}

@end
