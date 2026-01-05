//
//  BudgetCategoryCell.m
//  ExpenseTracker
//
//  Created by raven on 10/21/25.
//

#import <Foundation/Foundation.h>
#import "BudgetCategoryCell.h"
#import "CurrencyFormatterUtil.h"

@implementation BudgetCategoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self){
        self.categoryLabel = [[UILabel alloc] init];
        self.categoryLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.categoryLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
        [self.categoryLabel setContentHuggingPriority:UILayoutPriorityRequired
                                           forAxis:UILayoutConstraintAxisVertical];
        [self.categoryLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisVertical];
        
        self.infoLabel = [[UILabel alloc] init];
        self.infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.infoLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        self.infoLabel.textColor = [UIColor systemGrayColor];
        self.infoLabel.numberOfLines = 2;
        
        self.amountLabel = [[UILabel alloc] init];
        self.amountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.amountLabel.font = [UIFont monospacedDigitSystemFontOfSize:17 weight:UIFontWeightBold];
        self.amountLabel.textAlignment = NSTextAlignmentRight;
        
        [self.contentView addSubview:self.categoryLabel];
        [self.contentView addSubview:self.infoLabel];
        [self.contentView addSubview:self.amountLabel];
        
        CGFloat margin = 16.0;
        
        [NSLayoutConstraint activateConstraints:@[
            // Amount Label
            [self.amountLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.amountLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-margin],
            
            // Title Label
            [self.categoryLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:margin],
            [self.categoryLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:margin],
            [self.categoryLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.amountLabel.leadingAnchor constant:-8],
            
            // Info Label
            [self.infoLabel.topAnchor constraintEqualToAnchor:self.categoryLabel.bottomAnchor constant:4],
            [self.infoLabel.leadingAnchor constraintEqualToAnchor:self.categoryLabel.leadingAnchor],
            [self.infoLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.amountLabel.leadingAnchor constant:-8],
            [self.infoLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant: -margin]
            
        ]];
    }
    return self;
}

- (void)configureWithPlaceholder:(NSString *)placeholder
                           value:(NSDecimalNumber *)value
                      usedAmount:(NSDecimalNumber *)usedAmount
               installmentNumber:(NSInteger)installmentNumber
               totalInstallments:(NSInteger)totalInstallments
{
    if (totalInstallments > 1 && installmentNumber > 0) {
        self.categoryLabel.text = [NSString stringWithFormat:@"%@ (%ld/%ld)", placeholder, (long)installmentNumber, (long)totalInstallments];
    } else {
        self.categoryLabel.text = placeholder;
    }

    self.amountLabel.text = [[CurrencyFormatterUtil currencyFormatter] stringFromNumber:value];
    
    NSNumber *usedAmountNum = [self safeNumberFrom:usedAmount];
    NSNumber *valueNum = [self safeNumberFrom:value];
    NSNumber *remainingAmount = @([valueNum doubleValue] - [usedAmountNum doubleValue]);
    
    NSString *usedAmountText = [NSString stringWithFormat:@"Used Amount: %@", [[CurrencyFormatterUtil currencyFormatter] stringFromNumber:usedAmountNum]];
    NSString *remainingAmountText = [NSString stringWithFormat:@"Remaining Amount: %@", [[CurrencyFormatterUtil currencyFormatter] stringFromNumber:remainingAmount]];
    
    NSString *combinedText = [NSString stringWithFormat:@"%@\n%@", usedAmountText, remainingAmountText];
    self.infoLabel.text = combinedText;
}

- (NSNumber *)safeNumberFrom:(NSDecimalNumber *)decimalNumber {
    if (!decimalNumber || [decimalNumber isEqual:[NSDecimalNumber notANumber]]) {
        return @(0.0);
    }
    return (NSNumber *)decimalNumber;
}

@end
