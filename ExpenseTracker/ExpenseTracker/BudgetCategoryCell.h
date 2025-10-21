//
//  BudgetCategoryCell.h
//  ExpenseTracker
//
//  Created by raven on 10/21/25.
//

#ifndef BudgetCategoryCell_h
#define BudgetCategoryCell_h

#import <UIKit/UIKit.h>

@interface BudgetCategoryCell : UITableViewCell

@property (nonatomic, strong) UILabel *categoryLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UILabel *amountLabel;

- (void)configureWithPlaceholder:(NSString *)placeholder
                           value:(NSDecimalNumber *)value
                      usedAmount:(NSDecimalNumber *)usedAmount;

- (NSNumber *)safeNumberFrom:(NSDecimalNumber *)decimalNumber;


@end
#endif /* BudgetCategoryCell_h */
