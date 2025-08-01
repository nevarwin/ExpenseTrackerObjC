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
    // Get context
    NSManagedObjectContext *context = [(AppDelegate *)[[UIApplication sharedApplication] delegate] persistentContainer].viewContext;
    
    // Create fetch request for Category
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
    
    NSError *error = nil;
    NSArray *categories = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"Error fetching categories: %@", error);
        self.categoryValues = @[]; // Set empty if there's an error
        return;
    }
    
    // Extract names from the results
    NSMutableArray *names = [NSMutableArray array];
    for (NSManagedObject *category in categories) {
        NSString *name = [category valueForKey:@"name"];
        if (name) {
            [names addObject:name];
        }
    }
    
    self.categoryValues = names;
    
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
    
    // Create Segments
    NSArray *items = @[@"Expense", @"Income"];
    self.segmentControl = [[UISegmentedControl alloc] initWithItems:items];
    CGFloat margin = 16;
    CGFloat width = self.view.frame.size.width - 2 * margin;
    self.segmentControl.frame = CGRectMake(margin, 52, width, 32);
    
    // Set default selected segment
    self.segmentControl.selectedSegmentIndex = 0;
    
    // If editing an existing transaction, set segment index from transaction
    if (self.existingTransaction) {
        self.segmentControl.selectedSegmentIndex = self.existingTransaction.type;
    }
    
    // Add target for value changed
    [self.segmentControl addTarget:self
                            action:@selector(segmentChanged:)
                  forControlEvents:UIControlEventValueChanged];
    
    // Add to view
    [self.view addSubview:self.segmentControl];

}

-(void)segmentChanged:(UISegmentedControl *)sender {
    NSInteger selectedIndex = sender.selectedSegmentIndex;
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
        self.segmentControl.selectedSegmentIndex = self.existingTransaction.type;

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
    transaction.type = (int32_t)self.segmentControl.selectedSegmentIndex;
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Failed to save transaction: %@", error);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)datePicker:(UIDatePicker *)sender __attribute__((ibaction)) {
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self drawCircleIndicatorInView:self.view];
}

// In your UIView subclass or ViewController

- (void)drawCircleIndicatorInView:(UIView *)view {
    CGFloat lineWidth = 20.0;
    CGFloat radius = (MIN(view.bounds.size.width, view.bounds.size.height) - lineWidth) / 2.0;
    CGPoint center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));

    // 1. Background Circle (opacity 0.3)
    UIBezierPath *bgCirclePath = [UIBezierPath bezierPathWithArcCenter:center
                                                                radius:radius
                                                            startAngle:0
                                                              endAngle:2*M_PI
                                                             clockwise:YES];

    CAShapeLayer *bgCircleLayer = [CAShapeLayer layer];
    bgCircleLayer.path = bgCirclePath.CGPath;
    bgCircleLayer.strokeColor = [UIColor.redColor colorWithAlphaComponent:0.3].CGColor;
    bgCircleLayer.fillColor = UIColor.clearColor.CGColor;
    bgCircleLayer.lineWidth = lineWidth;

    [view.layer addSublayer:bgCircleLayer];

    // 2. Foreground Arc (trimmed, opacity 1.0)
    CGFloat startAngle = -M_PI_2; // Start at top
    CGFloat endAngle = startAngle + 2 * M_PI * 0.3; // 30% of the circle

    UIBezierPath *fgCirclePath = [UIBezierPath bezierPathWithArcCenter:center
                                                                radius:radius
                                                            startAngle:startAngle
                                                              endAngle:endAngle
                                                             clockwise:YES];

    CAShapeLayer *fgCircleLayer = [CAShapeLayer layer];
    fgCircleLayer.path = fgCirclePath.CGPath;
    fgCircleLayer.strokeColor = UIColor.redColor.CGColor;
    fgCircleLayer.fillColor = UIColor.blueColor.CGColor;
    fgCircleLayer.lineWidth = lineWidth;
    fgCircleLayer.lineCap = kCALineCapRound;

    [view.layer addSublayer:fgCircleLayer];
}

@end
