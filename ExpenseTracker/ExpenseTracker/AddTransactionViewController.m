//
//  AddTransactionViewController.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#import <Foundation/Foundation.h>
#import "AddTransactionViewController.h"

@interface AddTransactionViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>

@end

@implementation AddTransactionViewController

- (void) viewDidLoad{
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

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedCategory = self.categoryValues[row];
}




#pragma mark -

- (IBAction)addTransactionButton:(UIButton *)sender {
    NSLog(@"Amount: %@", self.amountTextField.text);
    NSLog(@"Picker Value: %@", self.selectedCategory);
    NSLog(@"Date: %@", self.datePickerOutlet.date);
}


- (void)datePicker:(UIDatePicker *)sender __attribute__((ibaction)) {
}

@end
