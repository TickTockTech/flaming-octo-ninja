
#import "AppDelegate.h"
#import "EJJavaScriptView.h"
@implementation AppDelegate
@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	// Optionally set the idle timer disabled, this prevents the device from sleep when
	// not being interacted with by touch. ie. games with motion control.
	application.idleTimerDisabled = YES;
	
	EJAppViewController *vc = [[EJAppViewController alloc] init];
    window.rootViewController = vc;
	[vc release];
	
    return YES;
}


#pragma mark -
#pragma mark Local Notifications

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *) notif {    
    NSNumber *show = [notif.userInfo objectForKey:@"showInGame"];
    
    if ([show intValue] == 1) {
        NSString *title = [notif.userInfo objectForKey:@"title"];
        NSString *message = [notif.userInfo objectForKey:@"message"];

        [self _showAlert:message withTitle:title];
        application.applicationIconBadgeNumber = notif.applicationIconBadgeNumber - 1;
    }
}

- (void) _showAlert:(NSString*)pushmessage withTitle:(NSString*)title {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:pushmessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    if (alertView) {
        [alertView release];
    }
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	window.rootViewController = nil;
	[window release];
    [super dealloc];
}


@end
