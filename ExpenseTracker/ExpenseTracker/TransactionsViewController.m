//
//  TransactionsViewController.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#import <Foundation/Foundation.h>
#import "TransactionsViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"

@interface TransactionsViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>

@end

@implementation TransactionsViewController

- (void) viewDidLoad{
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
    // Get Core Data Context
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    Transaction *transaction = self.isEditMode && self.existingTransaction.transactionId ? self.existingTransaction : [NSEntityDescription insertNewObjectForEntityForName:@"Transaction" inManagedObjectContext:context];
    
    if(self.isEditMode){
        self.amountTextField.text = [NSString stringWithFormat:@"%.2ld", (long)transaction.amount];
        
        NSUInteger categoryIndex = [self.categoryValues indexOfObject:transaction.category];
        if (categoryIndex != NSNotFound) {
            [self.pickerView selectRow:categoryIndex inComponent:0 animated:NO];
        }
        
        [self.datePickerOutlet setDate:transaction.date];
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
    //Get selected categor from picker
    NSInteger row = [self.pickerView selectedRowInComponent:0];
    NSString *category = self.categoryValues[row];
    
    //Parse amount using NSNumberFormatter for safety
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *amountNumber = [formatter numberFromString:self.amountTextField.text];
    NSInteger amount = amountNumber.integerValue;
    
    NSDate *date = self.datePickerOutlet.date;
    
    if (amount == 0 || !category.length || !date) {
        NSLog(@"Invalid input: Amount=%ld, Category=%@, Date=%@",
              (long)amount, category, date);
        return;
    }
    
    // Get Core Data Context
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    Transaction *transaction = self.isEditMode && self.existingTransaction.transactionId ? self.existingTransaction : [NSEntityDescription insertNewObjectForEntityForName:@"Transaction" inManagedObjectContext:context];
    
    //Assign transaction values
    if (self.isEditMode || !self.existingTransaction.transactionId){
        transaction.transactionId = [NSUUID UUID].UUIDString;
        transaction.updatedAt = [NSDate date];
    }
    
    transaction.amount = (int32_t)amount;
    transaction.category = category;
    transaction.date = date;
    transaction.createdAt = [NSDate date];
    transaction.updatedAt = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"Manually Dismissed");
}

- (void)datePicker:(UIDatePicker *)sender __attribute__((ibaction)) {
}

@end
