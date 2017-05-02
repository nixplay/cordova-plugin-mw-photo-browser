//
//  ImageViewer.h
//  Helper
//
//  Created by Calvin Lai on 7/11/13.
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "MWPhotoBrowser.h"
#import "IBActionSheet.h"
#import "XFDialogBuilder.h"
@interface MWPhotoBrowserCordova : CDVPlugin <MWPhotoBrowserDelegate,UINavigationControllerDelegate> {

    NSMutableDictionary* callbackIds;
    NSArray* photos;
    
}
@property (copy)   NSString* callbackId;
@property (nonatomic, retain) NSMutableDictionary* callbackIds;
@property (nonatomic, retain) NSArray *photos;
@property (nonatomic, retain) NSArray *thumbs;
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) MWGridViewController* gridViewController;
@property (nonatomic, retain) MWPhotoBrowser *browser;
@property (nonatomic, retain) IBActionSheet *actionSheet;
@property (nonatomic, retain) NSString *albumName;
@property (nonatomic, weak) XFDialogFrame *dialogView;
@property (nonatomic, weak) UIBarButtonItem *rightBarbuttonItem;
- (void)showGallery:(CDVInvokedUrlCommand*)command;

@end
