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
    self.transactionTableView.delegate = self;
    self.transactionTableView.dataSource = self;
    self.transactionsArray = [NSMutableArray array];
    
    CGFloat margin = 16;
    CGFloat width = self.view.frame.size.width - 2 * margin;
    CGFloat segmentHeight = 32;
    CGFloat gap = 8;
    
    // Get the Y position of the table view
    CGFloat tableViewY = CGRectGetMinY(self.transactionTableView.frame);
    
    // Calculate positions
    CGFloat dateSegmentY = tableViewY - segmentHeight - gap;
    CGFloat typeSegmentY = dateSegmentY - segmentHeight - gap;
    
    // Type segment (top)
    self.typeSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Expense", @"Income", @"All"]];
    self.typeSegmentControl.frame = CGRectMake(margin, typeSegmentY, width, segmentHeight);
    
    // Date segment (below type segment)
    self.dateSegmentControl = [[UISegmentedControl alloc] initWithItems:@[@"D", @"W", @"M", @"6M", @"Y"]];
    self.dateSegmentControl.frame = CGRectMake(margin, dateSegmentY, width, segmentHeight);
    
    // Add target for value changed
    [self.dateSegmentControl addTarget:self
                                action:@selector(dateSegmentChange:)
                      forControlEvents:UIControlEventValueChanged];
    
    [self.typeSegmentControl addTarget:self
                                action:@selector(typeSegmentChange:)
                      forControlEvents:UIControlEventValueChanged];
    
    self.typeSegmentControl.selectedSegmentIndex = 2;
    self.dateSegmentControl.selectedSegmentIndex = 0;
    
    [self.view addSubview:self.typeSegmentControl];
    [self.view addSubview:self.dateSegmentControl];
    
    // Updates the table for the defaults
    [self updateFetchPredicateForSegment:self.dateSegmentIndex typeIndex:@(self.typeSegmentIndex)];
    [self.transactionTableView reloadData];
    
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


- (IBAction)addTransaction:(UIButton *)sender {
    NSLog(@"Button Pressed");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TransactionsViewController"]) {
        UINavigationController *navController = segue.destinationViewController;
        TransactionsViewController *secondVC = (TransactionsViewController *)navController.topViewController;
        secondVC.isEditMode = NO;
        secondVC.delegate = self;
    }
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
