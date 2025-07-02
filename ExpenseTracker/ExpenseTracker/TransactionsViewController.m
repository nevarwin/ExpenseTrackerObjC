//
//  TransactionsViewController.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#import <Foundation/Foundation.h>
#import "TransactionsViewController.h"
#import "ViewController.h"

@interface TransactionsViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>

@end

@implementation TransactionsViewController

- (void) viewDidLoad{
    self.transactions = [NSMutableArray array];
    self.categoryValues = @[@"Apple", @"Banana", @"Orange"];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.amountTextField.delegate = self;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
    
    [self configureViewForMode];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (instancetype)initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination; {
    self = [super init];
    if (self) {
    }
    return self;
}

-(void)configureViewForMode{
    if(self.isEditMode){
        self.amountTextField.text = [NSString stringWithFormat:@"%.2ld", (long)self.existingTransaction.amount];
        
        NSUInteger categoryIndex = [self.categoryValues indexOfObject:self.existingTransaction.category];
        if (categoryIndex != NSNotFound) {
            [self.pickerView selectRow:categoryIndex inComponent:0 animated:NO];
        }
        
        [self.datePickerOutlet setDate:self.existingTransaction.createdAt];
        [self.button setTitle:@"Update" forState:UIControlStateNormal];
    } else {
        self.amountTextField.text = @"";
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        [self.datePickerOutlet setDate:[NSDate date]];
        [self.button setTitle:@"Add" forState:UIControlStateNormal];
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.amountTextField resignFirstResponder];
    return YES;
}



#pragma mark - UIPickerViewDataSource

// 1. Number of columns (aka components)
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// 2. Number of rows
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.categoryValues.count;
}



#pragma mark - UIPickerViewDelegate

// 3. Title for each row
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.categoryValues[row];
}



#pragma mark - Save Button

- (IBAction)addTransactionButton:(UIButton *)sender {
    NSInteger row = [self.pickerView selectedRowInComponent:0];
    self.selectedCategory = [self.categoryValues objectAtIndex:(NSUInteger)row];
    
    NSInteger amount = [self.amountTextField.text intValue];
    NSString *category = self.selectedCategory;
    NSDate *date = self.datePickerOutlet.date;
    
    if (amount == 0 || !category || !date) {
        NSLog(@"Invalid input: Amount=%ld, Category=%@, Date=%@",
              (long)amount, category, date);
        return;
    }
    
    Transaction *transaction;
    
    if (self.isEditMode && self.existingTransaction.transactionId) {
        self.existingTransaction.amount = amount;
        self.existingTransaction.category = category;
        self.existingTransaction.createdAt = date;
        
        transaction = self.existingTransaction;
        if ([self.delegate respondsToSelector:@selector(didUpdateTransaction:id:)]) {
            [self.delegate didUpdateTransaction:transaction id:self.existingTransaction.transactionId];
        }
    } else {
        transaction = [[Transaction alloc] init];
        transaction.transactionId = [[NSUUID UUID] UUIDString];
        transaction.amount = amount;
        transaction.category = category;
        transaction.createdAt = date;
        if ([self.delegate respondsToSelector:@selector(didSaveTransaction:)]) {
            [self.delegate didSaveTransaction:transaction];
        }
    }
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didUpdateItem:(Transaction *)item {
    NSLog(@"DidUpdateItem");
}

- (void)datePicker:(UIDatePicker *)sender __attribute__((ibaction)) {
}

@end
