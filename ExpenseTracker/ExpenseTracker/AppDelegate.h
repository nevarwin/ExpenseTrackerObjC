//
//  AppDelegate.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/26/25.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) NSDictionary<NSString *, NSAttributeDescription *> *incomeAttributes;
@property (nonatomic, strong) NSDictionary<NSString *, NSAttributeDescription *> *expenseAttributes;

- (void)saveContext;

- (NSDictionary<NSString *, NSDictionary<NSString *, NSAttributeDescription *> *> *)fetchAttributes;


@end

