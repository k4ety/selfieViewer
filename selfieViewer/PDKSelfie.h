//
//  PDKSelfie.h
//  selfieViewer
//
//  Created by Paul King on 7/18/15.
//  Copyright (c) 2015 Paul King. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDKSelfiePic.h"

@interface PDKSelfie : NSObject
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) PDKSelfiePic *standard;
@property (nonatomic, strong) PDKSelfiePic *lowRes;
@property (nonatomic, strong) PDKSelfiePic *thumbnail;
@end
