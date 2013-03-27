#import "EJBindingLocalNotification.h"

@implementation EJBindingLocalNotification

- (id)initWithContext:(JSContextRef)ctx 
    object:(JSObjectRef)obj 
    argc:(size_t)argc 
    argv:(const JSValueRef [])argv  {
    self = [super initWithContext:ctx object:obj argc:argc argv:argv];
    return self;
}

-(void)cancelAlarm: (NSInteger) id {
    for (UILocalNotification *notification in [[[UIApplication sharedApplication] scheduledLocalNotifications] copy]){
        NSDictionary *userInfo = notification.userInfo;
        if (id == [[userInfo objectForKey:@"id"] intValue]){
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}

-(void)scheduleAlarm: (NSInteger) id title: (NSString*) title message: (NSString*) message delay:(NSInteger) delay showInGame:(BOOL) showInGame {
    [self cancelAlarm: id]; //clear any previous alarms
    
    NSInteger show = showInGame ? 1 : 0;

    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    
    localNotif.alertAction = title;
    localNotif.alertBody = message;
    localNotif.fireDate = [NSDate dateWithTimeIntervalSinceNow: delay];
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.timeZone = [NSTimeZone defaultTimeZone];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInteger:id],    @"id",
        title,                              @"title",
        message,                            @"message",
        [NSNumber numberWithInteger:show],  @"showInGame",
        nil];
    localNotif.userInfo = userInfo;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

-(void)dealloc {
    [super dealloc];
}

EJ_BIND_FUNCTION (schedule, ctx, argc, argv) {
    if (argc == 4 || argc == 5) {
        NSInteger id = JSValueToNumberFast(ctx, argv[0]);
        NSString* title = JSValueToNSString(ctx, argv[1]);
        NSString* message = JSValueToNSString(ctx, argv[2]);
        NSInteger delay = JSValueToNumberFast(ctx, argv[3]);
        
        if (argc == 4) {
            [self scheduleAlarm: id title: title message: message delay: delay showInGame: FALSE ];
        } else {
            BOOL showInGame = JSValueToBoolean(ctx, argv[4]);
            [self scheduleAlarm: id title: title message: message delay: delay showInGame: showInGame ];
        }
    
        NSLog(@"NOTIFICATION SCHEDULED: #%d %@. Show in %d seconds.", id, title, delay);
    }
    
    return 0;
}

EJ_BIND_FUNCTION (cancel, ctx, argc, argv) {
    if (argc == 1) {
        NSInteger id = JSValueToNumberFast(ctx, argv[0]);
        [self cancelAlarm: id];
    
        NSLog(@"NOTIFICATION CANCEL: #%d.", id);
    }
    
    return 0;
}

EJ_BIND_FUNCTION (showNotifications, ctx, argc, argv) {
    for (UILocalNotification *notification in [[[UIApplication sharedApplication] scheduledLocalNotifications] copy]){
        NSDictionary *userInfo = notification.userInfo;
        NSLog(@"NOTIFICATION: #%d %@", [[userInfo objectForKey:@"id"] intValue], [userInfo objectForKey:@"title"]);
    }
    
    return 0;
}

@end
