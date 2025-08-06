//
//  ViewController.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/26/25.
//

#import "ViewController.h"
#import "Transaction.h"
#import "TransactionsViewController.h"
#import "AppDelegate.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupHeaderView];
    [self setupTableView];
    [self setupSegmentControls];
    
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
//    self.transactionsArray = [NSMutableArray array];
    
}

- (void)typeSegmentChange:(UISegmentedControl *)sender{
    self.typeSegmentIndex = sender.selectedSegmentIndex;
    [self updateFetchPredicateForSegment:self.dateSegmentIndex typeIndex:@(self.typeSegmentIndex)];
    [self.transactionTableView reloadData];
}

- (void)dateSegmentChange:(UISegmentedControl *)sender {
    self.dateSegmentIndex = sender.selectedSegmentIndex;
    [self updateFetchPredicateForSegment:self.dateSegmentIndex typeIndex:@(self.typeSegmentIndex)];
    [self.transactionTableView reloadData];
}

- (void)updateFetchPredicateForSegment:(NSInteger)dateIndex typeIndex:(NSNumber * _Nullable)typeIndex{
    NSMutableArray *subpredicates = [NSMutableArray array];
    [subpredicates addObject:[NSPredicate predicateWithFormat:@"isActive == YES"]];
    
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startDate = nil;
    
    switch (dateIndex) {
        case 0: // Day
            startDate = [calendar startOfDayForDate:now];
            break;
        case 1: // Week
            [calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&startDate interval:NULL forDate:now];
            break;
        case 2: // Month
            [calendar rangeOfUnit:NSCalendarUnitMonth startDate:&startDate interval:NULL forDate:now];
            break;
        case 3: // 6 Months
            startDate = [calendar dateByAddingUnit:NSCalendarUnitMonth value:-6 toDate:now options:0];
            break;
        case 4: // Year
            [calendar rangeOfUnit:NSCalendarUnitYear startDate:&startDate interval:NULL forDate:now];
            break;
        default:
            startDate = nil;
            break;
    }
    
    if (startDate) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"date >= %@", startDate]];
    }
    
    if (typeIndex != nil && [typeIndex integerValue] != 2) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"type == %@", typeIndex]];
    }
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"Fetch error: %@", error);
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TransactionsViewController"]) {
        UINavigationController *navController = segue.destinationViewController;
        TransactionsViewController *secondVC = (TransactionsViewController *)navController.topViewController;
        secondVC.isEditMode = NO;
        secondVC.delegate = self;
    }
}


#pragma mark - Actions

- (void)addButtonTapped {
    UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"TransactionNavController"];
    
    // Get your TransactionsViewController from the nav controller
    TransactionsViewController *transactionVC = (TransactionsViewController *)navController.topViewController;
    
    transactionVC.delegate = self;
    transactionVC.isEditMode = YES;
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - setupHeaderView
- (void)setupHeaderView {
    // Create header container
    self.headerContainer = [[UIView alloc] init];
    UIView *headerContainer = self.headerContainer;    headerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:headerContainer];
    
    // Setup header label (left side)
    self.headerLabel = [[UILabel alloc] init];
    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerLabel.text = @"Transactions";
    self.headerLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.headerLabel.textColor = [UIColor labelColor];
    [headerContainer addSubview:self.headerLabel];
    
    // Setup add button (right side)
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addButton.tintColor = [UIColor systemBlueColor];
    [self.addButton setTitle:@"Add Data" forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(addButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.addButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    // Increase button size to match Health app
    [self.addButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [headerContainer addSubview:self.addButton];
    
    // Setup constraints for header container
    [NSLayoutConstraint activateConstraints:@[
        [headerContainer.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [headerContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [headerContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [headerContainer.heightAnchor constraintEqualToConstant:60]
    ]];
    
    // Setup constraints for header label
    [NSLayoutConstraint activateConstraints:@[
        [self.headerLabel.leadingAnchor constraintEqualToAnchor:headerContainer.leadingAnchor],
        [self.headerLabel.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
        [self.headerLabel.trailingAnchor constraintEqualToAnchor:self.addButton.leadingAnchor constant:-10]
    ]];
    
    // Setup constraints for add button - make it larger like in Health app
    [NSLayoutConstraint activateConstraints:@[
        [self.addButton.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor],
        [self.addButton.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
    ]];
}


#pragma mark - setupSegmetControls

- (void)setupSegmentControls {
    // 1. Create the segment controls
    self.typeSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Expense", @"Income", @"All"]];
    self.typeSegmentControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.typeSegmentControl.selectedSegmentIndex = 2;
    
    self.dateSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"D", @"W", @"M", @"6M", @"Y"]];
    self.dateSegmentControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateSegmentControl.selectedSegmentIndex = 0;
    
    [self.typeSegmentControl addTarget:self
                                action:@selector(typeSegmentChange:)
                      forControlEvents:UIControlEventValueChanged];
    [self.dateSegmentControl addTarget:self
                                action:@selector(dateSegmentChange:)
                      forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.typeSegmentControl];
    [self.view addSubview:self.dateSegmentControl];
    
    // 2. Setup auto layout constraints
    CGFloat margin = 16.0;
    CGFloat segmentHeight = 32.0;
    CGFloat gap = 8.0;
    
    [NSLayoutConstraint activateConstraints:@[
        // Type segment at top, under safe area
        [self.typeSegmentControl.topAnchor constraintEqualToAnchor:self.headerContainer.bottomAnchor constant:16.0],
        [self.typeSegmentControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:margin],
        [self.typeSegmentControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-margin],
        [self.typeSegmentControl.heightAnchor constraintEqualToConstant:segmentHeight],
        
        // Date segment under type segment
        [self.dateSegmentControl.topAnchor constraintEqualToAnchor:self.typeSegmentControl.bottomAnchor constant:gap],
        [self.dateSegmentControl.leadingAnchor constraintEqualToAnchor:self.typeSegmentControl.leadingAnchor],
        [self.dateSegmentControl.trailingAnchor constraintEqualToAnchor:self.typeSegmentControl.trailingAnchor],
        [self.dateSegmentControl.heightAnchor constraintEqualToConstant:segmentHeight],
        
        // Table view below date segment (modify your tableView's top constraint!)
        [self.transactionTableView.topAnchor constraintEqualToAnchor:self.dateSegmentControl.bottomAnchor constant:gap]
    ]];
    
    // 3. Initialize states
    self.typeSegmentIndex = self.typeSegmentControl.selectedSegmentIndex;
    self.dateSegmentIndex = self.dateSegmentControl.selectedSegmentIndex;
}


#pragma mark - setupTableView
- (void)setupTableView {
    // Setup table view for budget items - use inset grouped style like Health app
    self.transactionTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.transactionTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.transactionTableView.delegate = self;
    self.transactionTableView.dataSource = self;
    
    // Clear background to match the parent view background
    self.transactionTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.transactionTableView];
    
    // Register cell with subtitle style to show budget amounts
    [self.transactionTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"BudgetCell"];
    
    // Setup constraints for table view
    [NSLayoutConstraint activateConstraints:@[
        [self.transactionTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.transactionTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.transactionTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}




#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"TransactionsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    Transaction *transaction = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    NSString *formattedDate = [dateFormatter stringFromDate:transaction.date];
    
    // Type indicator emoji
    NSString *typeIndicator = transaction.type == 0 ? @"💸" : @"💰";
    
    // Currency formatting
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    NSString *formattedAmount = [currencyFormatter stringFromNumber:@(transaction.amount)];
    
    // Create a label for the date
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
    dateLabel.text = formattedDate;
    dateLabel.font = [UIFont systemFontOfSize:12];
    dateLabel.textColor = [UIColor grayColor];
    dateLabel.textAlignment = NSTextAlignmentRight;
    
    cell.imageView.image = [self emojiToImage:typeIndicator];
    cell.textLabel.text = formattedAmount;
    cell.detailTextLabel.text = transaction.category;
    cell.accessoryView = dateLabel;
    
    return cell;
}

// Helper method to convert emoji to image
- (UIImage *)emojiToImage:(NSString *)emoji {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    label.text = emoji;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:24];
    
    UIGraphicsBeginImageContextWithOptions(label.bounds.size, NO, 0.0);
    [label.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    // Instantiate the navigation controller
    UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"TransactionNavController"];
    
    // Get your TransactionsViewController from the nav controller
    TransactionsViewController *transactionVC = (TransactionsViewController *)navController.topViewController;
    
    transactionVC.delegate = self;
    // Fetch the Transaction object directly from NSFetchedResultsController
    Transaction *selectedTransaction = [self.fetchedResultsController objectAtIndexPath:indexPath];
    transactionVC.existingTransaction = selectedTransaction;
    transactionVC.isEditMode = YES;
    [self presentViewController:navController animated:YES completion:nil];
    
}

// Deleting via swipe gesture
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Fetch the Transaction object directly from NSFetchedResultsController
        Transaction *transactionToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath ];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
        //[context deleteObject:transactionToDelete]; // Actual Deletion
        transactionToDelete.isActive = NO;
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Error deleting transaction: %@, %@", error, error.userInfo);
            // Optionally: present an alert or error to user
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Transactions";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"Tap Add Data to add a new transaction";
}



#pragma mark - FetchResultsController
- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Transaction"];
    
    // Add predicate to only fetch active transactions
    NSPredicate *activePredicate = [NSPredicate predicateWithFormat:@"isActive == YES"];
    fetchRequest.predicate = activePredicate;
    
    // Sort: newest first
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    fetchRequest.sortDescriptors = @[sort];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc]
                                 initWithFetchRequest:fetchRequest
                                 managedObjectContext:context
                                 sectionNameKeyPath:nil
                                 cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
    
    return _fetchedResultsController;
}



#pragma mark - NSFetchResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.transactionTableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.transactionTableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.transactionTableView;
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }
}

@end
