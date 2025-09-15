//
//  Transaction+CoreDataClass.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 9/15/25.
//
//

#import "Transaction+CoreDataClass.h"

@implementation Transaction

- (void)awakeFromInsert {
    [super awakeFromInsert];

    NSDate *now = [NSDate date];
    [self setPrimitiveValue:now forKey:@"createdAt"];
}


- (void)willSave {
    [super willSave];

    if (self.isInserted) {
        // Fresh object, don't change updatedAt — it's already set in awakeFromInsert
        return;
    }

    if (self.hasChanges) {
        NSDate *now = [NSDate date];
        [self setPrimitiveValue:now forKey:@"updatedAt"];
    }
}


@end
