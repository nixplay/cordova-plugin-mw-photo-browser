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
#import "IBActionSheet.h"
#import "UIImage+MWPhotoBrowser.h"
#import <Cordova/CDVPlugin+Resources.h>
// #import <Cordova/CDVDebug.h>


@implementation MWPhotoBrowserCordova

@synthesize callbackIds = _callbackIds;
@synthesize photos = _photos;
@synthesize thumbs = _thumbs;
@synthesize browser = _browser;
@synthesize data = _data;
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
    _data = [options objectForKey:@"data"];
    
//    NSLog(@"data %@",_data);
    for (NSString* url in [options objectForKey:@"images"])
    {
        [images addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }
    for (NSString* url in [options objectForKey:@"thumbnails"])
    {
        [thumbs addObject:[MWPhoto photoWithURL:[NSURL URLWithString: url]]];
    }

    self.photos = images;
    if([thumbs count] == 0){
        self.thumbs = self.photos;
    }else{
        self.thumbs = thumbs;
    }
    
    

    
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
    NSString* resourceIdentifier = [NSString stringWithFormat:@"%@.bundle/%@", NSStringFromClass([self class]), @"images/options.png"];
    
    [UIImage imageNamed:resourceIdentifier];
    
     UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed:resourceIdentifier] style:UIBarButtonItemStylePlain target:self action:@selector(home:)];
     browser.navigationItem.rightBarButtonItem = newBackButton;
    
    
    _navigationController.delegate = self;
    
    CATransition *transition = [[CATransition alloc] init];
    transition.duration = 0.35;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [self.viewController.view.window.layer addAnimation:transition forKey:kCATransition];
    [self.viewController presentViewController:nc animated:NO completion:^{
        
    }];
//    [self.viewController presentViewController:nc animated:YES completion:nil];
    
    //[nc release];

    // Release
    //[browser release];
    //[images release];

}

-(void)home:(UIBarButtonItem *)sender
{
//    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    IBActionSheet *actionSheet = [[IBActionSheet alloc] initWithTitle:NSLocalizedString(@"Options", nil)
                                                             callback:^(IBActionSheet *actionSheet, NSInteger buttonIndex) {
                                                                 NSLog(@"actionSheet %@ %li",actionSheet , (long)buttonIndex);
                                                             }
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil, nil];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Select Photos", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Add Album to Playlist", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit Album Name", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete Album", nil)];
    [actionSheet  showInView:self.navigationController.view ];
//    - (id)initWithTitle:(NSString *)title delegate:(id<IBActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelTitle destructiveButtonTitle:(NSString *)destructiveTitle otherButtonTitles:(NSString *)otherTitles, ... NS_REQUIRES_NIL_TERMINATION;
//    
//    - (void)showInView:(UIView *)theView;

    
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
    [browser dismissViewControllerAnimated:YES completion:nil];
}

//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index{
//}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index{
    NSLog(@"didDisplayPhotoAtIndex %lu", (unsigned long)index);
}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index{
    NSLog(@"actionButtonPressedForPhotoAtIndex %lu", (unsigned long)index);
}
//- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index{}
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected{
    NSLog(@"photoAtIndex %lu selectedChanged %i", (unsigned long)index , selected);
}
//- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser showHideGridController:(MWGridViewController*)gridController{}

@end
