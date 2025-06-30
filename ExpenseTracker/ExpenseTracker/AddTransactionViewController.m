//
//  AddTransactionViewController.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#import <Foundation/Foundation.h>
#import "AddTransactionViewController.h"
#import "ViewController.h"

@interface AddTransactionViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, AddTransactionDelegate>

@end

@implementation AddTransactionViewController

- (void) viewDidLoad{
    self.transactions = [NSMutableArray array];
    self.categoryValues = @[@"Apple", @"Banana", @"Orange"];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.amountTextField.delegate = self;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
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
    
    Transaction *transaction = [[Transaction alloc] initWithAmount:amount category:category createdAt:date];
    
    [self.delegate didSaveTransactions:transaction];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)datePicker:(UIDatePicker *)sender __attribute__((ibaction)) {
}

@end
