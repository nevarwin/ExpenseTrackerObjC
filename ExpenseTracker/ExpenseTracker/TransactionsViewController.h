//
//  TransactionsViewController.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#ifndef TransactionsViewController_h
#define TransactionsViewController_h

#import <UIKit/UIKit.h>
#import "Transaction.h"


@interface TransactionsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePickerOutlet;
@property (strong, nonatomic) NSArray *categoryValues;
@property (weak, nonatomic) NSString *selectedCategory;

@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) Transaction *existingTransaction;

@property (strong, nonatomic) UIBarButtonItem *rightButton;
@property (strong, nonatomic) UIBarButtonItem *leftButton;


- (IBAction)datePicker:(UIDatePicker *)sender;

- (void)configureViewForMode;

@end

#endif /* TransactionsViewController_h */
