//
//  SceneDelegate.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/26/25.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "ViewController.h"
#import "BudgetViewController.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // Load the storyboard
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Instantiate view controllers from storyboard
    UIViewController *transactionVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionViewController"];
    transactionVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Transactions"
                                                             image:[UIImage systemImageNamed:@"heart.fill"]
                                                               tag:0];
    
    UIViewController *budgetVC = [[BudgetViewController alloc] init];
    budgetVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Budget"
                                                        image:[UIImage systemImageNamed:@"magnifyingglass"]
                                                          tag:1];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[transactionVC, budgetVC];
    
    // Customize tab bar appearance
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor systemBackgroundColor];
    appearance.stackedLayoutAppearance.selected.iconColor = [UIColor systemTealColor];
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor systemTealColor]};
    appearance.stackedLayoutAppearance.normal.iconColor = [UIColor labelColor];
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor labelColor]};
    
    tabBarController.tabBar.standardAppearance = appearance;
    if (@available(iOS 15.0, *)) {
        tabBarController.tabBar.scrollEdgeAppearance = appearance;
    }
    
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
    
    // Save changes in the application's managed object context when the application transitions to the background.
    [(AppDelegate *)UIApplication.sharedApplication.delegate saveContext];
}


@end
