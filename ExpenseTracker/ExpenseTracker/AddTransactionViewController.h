//
//  AddTransactionViewController.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#ifndef AddTransactionViewController_h
#define AddTransactionViewController_h

#import <UIKit/UIKit.h>
#import "Transaction.h"

@interface AddTransactionViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@property (strong, nonatomic) NSArray *categoryValues;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;

- (IBAction)addTransactionButton:(UIButton *)sender;

- (IBAction)datePicker:(UIDatePicker *)sender;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePickerOutlet;

@property (weak, nonatomic) NSString *selectedCategory;

@property (nonatomic, strong) NSMutableArray<Transaction *> *transactions;

@property (nonatomic, weak) id delegate;

@end


#endif /* AddTransactionViewController_h */
