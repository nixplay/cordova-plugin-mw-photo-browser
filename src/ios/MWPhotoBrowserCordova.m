//
//  ImageViewer.m
//  Helper
//
//  Created by Calvin Lai on 7/11/13.
//
//

#import "MWPhotoBrowserCordova.h"
#import "MWPhotoBrowser.h"
#import <Cordova/CDVViewController.h>
// #import <Cordova/CDVDebug.h>


@implementation MWPhotoBrowserCordova

@synthesize callbackIds = _callbackIds;
@synthesize photos = _photos;
@synthesize thumbs = _thumbs;
@synthesize browser = _browser;
@synthesize navigationController = _navigationController;
- (NSMutableDictionary*)callbackIds {
    if(_callbackIds == nil) {
      _callbackIds = [[NSMutableDictionary alloc] init];
    }
    return _callbackIds;
}

- (void)showGallery:(CDVInvokedUrlCommand*)command {
    NSLog(@"showGalleryWith:%@", command.arguments);

    [self.callbackIds setValue:command.callbackId forKey:@"showGallery"];

    NSDictionary *options = [command.arguments objectAtIndex:0];
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    NSUInteger photoIndex = [[options objectForKey:@"index"] intValue];

    for (NSString* url in [options objectForKey:@"images"])
    {
        [images addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }
    for (NSString* url in [options objectForKey:@"thumbnails"])
    {
        [thumbs addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }

    self.photos = images;
    self.thumbs = thumbs;
    
    

    
    // Create & present browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate: self];
    _browser = browser;
    // Set options
//    browser.wantsFullScreenLayout = NO; // Decide if you want the photo browser full screen, i.e. whether the status bar is affected (defaults to YES)
    browser.displayActionButton = YES; // Show action button to save, copy or email photos (defaults to NO)
    browser.startOnGrid = YES;
    browser.enableGrid = YES;
    browser.displayNavArrows = YES;
    browser.displayActionButton = YES;
    [browser setCurrentPhotoIndex: photoIndex]; // Example: allows second image to be presented first

    // Modal
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    _navigationController = nc;
    // UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home", nil) style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
    // browser.navigationItem.leftBarButtonItem = newBackButton;
    
    
    _navigationController.delegate = self;
    
    CATransition *transition = [[CATransition alloc] init];
    transition.duration = 0.5;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [self.viewController.view.window.layer addAnimation:transition forKey:kCATransition];
    [self.viewController presentViewController:nc animated:NO completion:nil];
//    [self.viewController presentViewController:nc animated:YES completion:nil];
    
    //[nc release];

    // Release
    //[browser release];
    //[images release];

}

-(void)home:(UIBarButtonItem *)sender
{
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.35;
    transition.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionMoveIn;
    transition.subtype = kCATransitionFromLeft;
    [self.navigationController.view.window.layer addAnimation:transition forKey:kCATransition];
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}


// -(void)action:(UIBarButtonItem *)sender
// {
//     _browser.displaySelectionButtons = !_browser.displaySelectionButtons;
//     [_browser setNeedsFocusUpdate];
//     NSLog(@"action %@",sender);
// }


#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if([viewController isKindOfClass:[MWPhotoBrowser class] ]){
        // UIBarButtonItem *newActionButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"action", nil) style:UIBarButtonItemStylePlain target:self action:@selector(action:)];
        // viewController.navigationItem.rightBarButtonItem = newActionButton;
        
    }
//else{
//        [self.viewController dismissViewControllerAnimated:YES completion:nil];
//    }
}


#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index{
    MWPhoto *photo = [self.thumbs objectAtIndex:index];
    return photo;
}
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    MWPhoto *photo = [self.photos objectAtIndex:index];
    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
    return captionView;
}

-(void) photoBrowserDidFinishModalPresentation:(MWPhotoBrowser*) browser{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}
@end
