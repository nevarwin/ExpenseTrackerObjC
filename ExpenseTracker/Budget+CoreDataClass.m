//
//  Budget+CoreDataClass.m
//  ExpenseTracker
//
//  Created by raven on 9/15/25.
//
//

#import "Budget+CoreDataClass.h"

@implementation Budget

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
