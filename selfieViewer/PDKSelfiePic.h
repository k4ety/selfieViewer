//
//  PDKSelfiePic.h
//  selfieViewer
//
//  Created by Paul King on 7/18/15.
//  Copyright (c) 2015 Paul King. All rights reserved.
//

@import UIKit;
#import <Foundation/Foundation.h>

@interface PDKSelfiePic : NSObject
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) UIImage *image;
@end
