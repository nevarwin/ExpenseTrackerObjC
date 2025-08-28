//
//  Transaction.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#ifndef Transaction_h
#define Transaction_h
#import <CoreData/CoreData.h>

@interface Transaction  : NSManagedObject

@property (nullable, nonatomic, copy) NSString *transactionId;
@property (nonatomic) int32_t amount;
@property (nullable, nonatomic, copy) NSString *category;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nullable, nonatomic, copy) NSDate *updatedAt;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic) NSInteger type;
@property (nonatomic) int32_t budget;

@end

#endif /* Transaction_h */

