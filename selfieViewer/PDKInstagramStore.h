//
//  PDKInstagramStore.h
//  selfieViewer
//
//  Created by Paul King on 7/18/15.
//  Copyright (c) 2015 Paul King. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDKInstagramStore : NSObject
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSMutableArray *collection;

+ (instancetype)sharedStore;

-(void)getAuth:(UIView *)view;
-(void)getPicsWithTag: (NSString *)tag;
-(void)getMorePics;
-(UIImage *)getImageFromURL:(NSString *)url;
@end
