//
//  Transaction.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#ifndef Transaction_h
#define Transaction_h

@interface Transaction  : NSObject

@property (nonatomic, nonatomic) NSInteger *amount;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSDate *createdAt;

- (instancetype)initWithAmount:(NSInteger *)amount
                      content:(NSString *)category
                    createdAt:(NSDate *)createdAt;

@end

#endif /* Transaction_h */
