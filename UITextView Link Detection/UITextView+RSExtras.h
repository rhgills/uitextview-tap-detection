//
//  UITextView+RSExtras2.h
//  UITextView Link Detection
//
//  Created by Robert on 6/22/13.
//  Copyright (c) 2013 Robert Gilliam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (RSExtras2)

- (NSString *)rs_potentialLinkAtPoint:(CGPoint)point;
- (NSString *)rs_linkAtPoint:(CGPoint)point;

// for tests
- (UITextPosition *)closestPositionNotAtEndOfDocumentToPoint:(CGPoint)point;

- (void)appendToString:(NSMutableString *)s byMovingLeftFromAndNotIncludingTextPosition:(UITextPosition *)textPosition;
- (id)appendToString:(NSMutableString *)s byMovingRightFromAndIncludingTextPosition:(UITextPosition *)textPosition;

- (BOOL)potentialLinkIsEmpty:(NSString *)potentialLink;

@end
