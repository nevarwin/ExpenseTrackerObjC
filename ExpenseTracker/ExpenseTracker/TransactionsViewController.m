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
    
    self.title = @"Transaction";
    
    // Left bar button item
    self.leftButton = [[UIBarButtonItem alloc]
                       initWithTitle:@"Back"
                       style:UIBarButtonItemStylePlain
                       target:self
                       action:@selector(leftButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.leftButton;
    
    
    // Right bar button item
    self.rightButton = [[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                        target:self
                        action:@selector(rightButtonTapped)];
    self.navigationItem.rightBarButtonItem = self.rightButton;
}

- (void)leftButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
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
        
        [self.datePickerOutlet setDate:self.existingTransaction.date];
    } else {
        self.amountTextField.text = @"";
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
        [self.datePickerOutlet setDate:[NSDate date]];
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

- (void)rightButtonTapped {
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
    
    Transaction *transaction;
    
    //Assign transaction values
    if (self.isEditMode && self.existingTransaction.transactionId) {
        transaction = self.existingTransaction;
        transaction.updatedAt = [NSDate date];
    } else {
        transaction = [NSEntityDescription insertNewObjectForEntityForName:@"Transaction" inManagedObjectContext:context];
        transaction.createdAt = [NSDate date];
        transaction.transactionId = [[NSUUID UUID] UUIDString];
    }
    
    transaction.amount = (int32_t)amount;
    transaction.category = category;
    transaction.date = date;
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Failed to save transaction: %@", error);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"Manually Dismissed");
}

- (void)datePicker:(UIDatePicker *)sender __attribute__((ibaction)) {
}

@end
