//
//  Category+CoreDataClass.m
//  ExpenseTracker
//
//  Created by raven on 1/6/26.
//
//

#import "Category+CoreDataClass.h"

@implementation Category

- (BOOL)isValidForDate:(NSDate *)date {
    if (!self.isInstallment) {
        return YES;
    }
    
    NSDate *installmentStart = self.installmentStartDate;
    if (!installmentStart) {
        return YES; // Or NO? If data is missing. Assuming YES to be safe or NO strictly.
                    // Original code returned NO (isNotWithin = NO -> Valid).
        return YES;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *currentComps = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:date];
    NSInteger currentMonth = currentComps.month;
    NSInteger currentYear = currentComps.year;
    
    NSInteger currentTotalMonths = (currentYear * 12) + currentMonth;
    
    NSDateComponents *startComps = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:installmentStart];
    NSInteger startTotalMonths = (startComps.year * 12) + startComps.month;
    NSInteger lastValidTotalMonths = startTotalMonths + self.installmentMonths - 1;
    
    if (currentTotalMonths >= startTotalMonths && currentTotalMonths <= lastValidTotalMonths) {
        return YES;
    }
    return NO;
}

@end
