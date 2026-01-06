//
//  CurrencyFormatterUtil.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 10/7/25.
//

#import <Foundation/Foundation.h>
#import "CurrencyFormatterUtil.h"

@implementation CurrencyFormatterUtil : NSObject
+ (NSNumberFormatter *)currencyFormatter {
    static NSNumberFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.maximumFractionDigits = 2;
    });
    return formatter;
}
@end
