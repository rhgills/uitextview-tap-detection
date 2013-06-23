//
//  RHGAutoverifyingSenTestCase.h
//  Phoenix
//
//  Created by Robert Gilliam on 6/19/13.
//  Copyright (c) 2013 Robert Gilliam. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>


// This little block can probably go away with the next version of developer tools:
#ifndef NS_REQUIRES_SUPER
# if __has_attribute(objc_requires_super)
#  define NS_REQUIRES_SUPER __attribute((objc_requires_super))
# else
#  define NS_REQUIRES_SUPER
# endif
#endif



@interface RHGAutoverifyingSenTestCase : SenTestCase

- (void)setUp NS_REQUIRES_SUPER;
- (void)tearDown NS_REQUIRES_SUPER;

/// Calls +[OCMockObject mockForClass:] and adds the mock and call -verify on it during -tearDown
- (id)autoVerifiedMockForClass:(Class)aClass;
/// C.f. -autoVerifiedMockForClass:
- (id)autoVerifiedPartialMockForObject:(id)object;
/// C.f. - autoVerifiedMockForClass:
- (id)autoVerifiedMockForProtocol:(Protocol *)protocol;

/// Calls -verify on the mock during -tearDown
- (void)verifyDuringTearDown:(id)mock;

@end
