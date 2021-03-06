//
//  MFMessageComposeViewController+BlocksKit.m
//  BlocksKit
//

#import "MFMessageComposeViewController+BlocksKit.h"
#import "NSObject+BlocksKit.h"

static char *kDelegateKey = "MFMessageComposeViewControllerDelegate";
static char *kCompletionHandlerKey = "MFMessageComposeViewControllerCompletion";

#pragma mark Delegate

@interface BKMessageComposeViewControllerDelegate : NSObject <MFMessageComposeViewControllerDelegate>

+ (id)shared;

@end

@implementation BKMessageComposeViewControllerDelegate

+ (id)shared {
    static id __strong proxyDelegate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxyDelegate = [BKMessageComposeViewControllerDelegate new];
    });
    return proxyDelegate;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    id delegate = controller.messageComposeDelegate;
    if (delegate && [delegate respondsToSelector:@selector(messageComposeViewController:didFinishWithResult:)])
        [delegate messageComposeViewController:controller didFinishWithResult:result];
    else {
        #ifdef __IPHONE_5_0 // preemptive compatibility with the 5.0 SDK
        if ([controller respondsToSelector:@selector(presentingViewController)]) 
            [[controller presentingViewController] dismissModalViewControllerAnimated:YES]; // iOS 5
        else
        #endif
            [controller.parentViewController dismissModalViewControllerAnimated:YES]; // 4.3 and below
    }
    
    BKMessageComposeBlock block = controller.completionHandler;
    if (block)
        block(result);
}

@end

#pragma mark Category

@implementation MFMessageComposeViewController (BlocksKit)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSelector:@selector(messageComposeDelegate) withSelector:@selector(bk_messageComposeDelegate)];
        [self swizzleSelector:@selector(setMessageComposeDelegate:) withSelector:@selector(bk_setMessageComposeDelegate:)];
    });
}

#pragma mark Methods

- (id)bk_messageComposeDelegate {
    return [self associatedValueForKey:kDelegateKey];
}

- (void)bk_setMessageComposeDelegate:(id)delegate {
    [self weaklyAssociateValue:delegate withKey:kDelegateKey];
    [self bk_setMessageComposeDelegate:[BKMessageComposeViewControllerDelegate shared]];
}

#pragma mark Properties

- (BKMessageComposeBlock)completionHandler {
    return [self associatedValueForKey:kCompletionHandlerKey];
}

- (void)setCompletionHandler:(BKMessageComposeBlock)handler {
    [self bk_setMessageComposeDelegate:[BKMessageComposeViewControllerDelegate shared]];
    [self associateCopyOfValue:handler withKey:kCompletionHandlerKey];
}

@end

