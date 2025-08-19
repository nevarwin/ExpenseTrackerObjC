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

@property (weak, nonatomic) UIPickerView *pickerView;
@property (weak, nonatomic) UITextField *amountTextField;
@property (weak, nonatomic) UIDatePicker *datePickerOutlet;

@property (strong, nonatomic) NSArray *categoryValues;
@property (weak, nonatomic) NSString *selectedCategory;

@property (strong, nonatomic) NSDictionary *expenseAttributes;
@property (strong, nonatomic) NSDictionary *incomeAttributes;

@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) Transaction *existingTransaction;

@property (strong, nonatomic) UIBarButtonItem *rightButton;
@property (strong, nonatomic) UIBarButtonItem *leftButton;

@property (strong, nonatomic) UISegmentedControl *segmentControl;

@property (nonatomic, strong) UITableView *tableView;

- (IBAction)datePicker:(UIDatePicker *)sender;

- (void)configureViewForMode;

@end

#endif /* TransactionsViewController_h */
