//
//  UITextView_Link_DetectionTests.m
//  UITextView Link DetectionTests
//
//  Created by Robert on 6/22/13.
//  Copyright (c) 2013 Robert Gilliam. All rights reserved.
//

#import "UITextView_Link_DetectionTests.h"

#import "UITextView+RSExtras.h"
#import "NSString+RSExtras.h"

#import <OCMock.h>
#define HC_SHORTHAND
#import <OCHamcrest.h>

#import <CoreGraphics/CoreGraphics.h>



@interface FakeTextRange : UITextRange

@property (readwrite, nonatomic) UITextPosition *end;

@end

@implementation FakeTextRange

@synthesize end = _end;

@end




@implementation UITextView_Link_DetectionTests {
    UITextView *textView;
    id fakeTextView;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    textView = [[UITextView alloc] initWithFrame:CGRectZero];
    fakeTextView = [OCMockObject partialMockForObject:textView];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

#pragma mark - Test rs_linkAtPoint (testing potentialLinkIsEmpty. linkFromPotentialLink implicity)
/** 
 These tests are good, and can test the potentialLinkIsEmpty method implicitly. That means
 that that method is OK to be a private helper.
 */
- (void)testNoLinkIfNoPotentialLink
{
    CGPoint point = CGPointZero;
    [[[fakeTextView stub] andReturn:nil] rs_potentialLinkAtPoint:point];
    
    NSString *link = [textView rs_linkAtPoint:point];
    STAssertNil(link, nil);
}

- (void)testNoLinkIfEmptyPotentialLink
{
    CGPoint point = CGPointZero;
    [[[fakeTextView stub] andReturn:@""] rs_potentialLinkAtPoint:point];
    
    NSString *link = [textView rs_linkAtPoint:point];
    STAssertNil(link, nil);
}

- (void)testNoLinkIfNoActualLinks
{
    NSString *potentialLink = @"example.com";
    id fakePotentialLink = [OCMockObject partialMockForObject:potentialLink];
    
    
    CGPoint point = CGPointZero;
    [[[fakeTextView stub] andReturn:fakePotentialLink] rs_potentialLinkAtPoint:point];
    
    [[[fakePotentialLink stub] andReturn:nil] rs_links];
    NSString *link = [textView rs_linkAtPoint:point];
    
    STAssertNil(link, nil);
}

- (void)testNoLinkIfZeroActualLinks
{
    NSString *potentialLink = @"example.com";
    id fakePotentialLink = [OCMockObject partialMockForObject:potentialLink];
    
    
    CGPoint point = CGPointZero;
    [[[fakeTextView stub] andReturn:fakePotentialLink] rs_potentialLinkAtPoint:point];
    
    [[[fakePotentialLink stub] andReturn:@[]] rs_links];
    NSString *link = [textView rs_linkAtPoint:point];
    
    STAssertNil(link, nil);
}

- (void)testLinkIsFirstActualLink
{
    NSString *potentialLink = @"example.com";
    id fakePotentialLink = [OCMockObject partialMockForObject:potentialLink];
    
    [[[fakeTextView stub] andReturn:fakePotentialLink] rs_potentialLinkAtPoint:CGPointZero];
    
    [[[fakePotentialLink stub] andReturn:@[@"first", @"second"]] rs_links];
    NSString *link = [textView rs_linkAtPoint:CGPointZero];
    
    STAssertEqualObjects(link, @"first", nil);
}


#pragma mark - Test Potential Link at Point
// possible refactoring generalization: contingous block of text/a word detection!
- (void)testNoPotentialLinkIfAtEndOfDocumentShorter
{
    CGPoint pointAtEndOfDocument = CGPointZero;
    [[[fakeTextView stub] andReturn:nil] closestPositionNotAtEndOfDocumentToPoint:pointAtEndOfDocument];
    
    NSString *potentialLink = [textView rs_potentialLinkAtPoint:pointAtEndOfDocument];
    
    assertThatInteger([potentialLink length], equalToInteger(0)); // a little coupled to implementation? nil or empty is OK
}

// test closestPosition
- (void)testClosestPositionToEndOfDocumentNotAtEndOfDocumentIsClosestPosition
{
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){NO})] characterAtPositionIsLastCharacterInDocument:CGPointZero];
    
    id closestPosition = [self newMock];
    [[[fakeTextView stub] andReturn:closestPosition] closestPositionToPoint:CGPointZero];
    
    assertThat([textView closestPositionNotAtEndOfDocumentToPoint:CGPointZero], sameInstance(closestPosition));
}

- (void)testNoClosestPositionNotAtEndOfDocumentIfAtEndOfDocument
{
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] characterAtPositionIsLastCharacterInDocument:CGPointZero];

    assertThat([textView closestPositionNotAtEndOfDocumentToPoint:CGPointZero], nilValue());
}

- (void)testCharacterAtPositionIsLastInDocument
{
    id endOfDocumentPosition = [self newMock];
    
    id textRange = [OCMockObject mockForClass:[UITextRange class]];
    [[[textRange stub] andReturn:endOfDocumentPosition] end];
    
    [[[fakeTextView stub] andReturn:textRange] characterRangeAtPoint:CGPointZero];
    
    [[[fakeTextView stub] andReturn:endOfDocumentPosition] endOfDocument];
    
    assertThatBool([textView characterAtPositionIsLastCharacterInDocument:CGPointZero], equalToBool(YES));
}

- (void)testCharacterAtPositionIsNotLastInDocument
{
    id endOfDocumentPosition = [self newMock];
    id otherTextPosition = [self newMock];
    
    id textRange = [OCMockObject mockForClass:[UITextRange class]];
    [[[textRange stub] andReturn:otherTextPosition] end];
    
    [[[fakeTextView stub] andReturn:textRange] characterRangeAtPoint:CGPointZero];
    
    [[[fakeTextView stub] andReturn:endOfDocumentPosition] endOfDocument];
    
    assertThatBool([textView characterAtPositionIsLastCharacterInDocument:CGPointZero], equalToBool(NO));
}

// isEmpty HCMatcher
// if count or length is responded to and is 0, or if nil - isEmpty
// if both responded to, undefined - throw to warn

// alternately: isEmptyCollection, isEmptyString() or nil?

- (void)testNoPotentialLinkIfAtEndOfDocument
{
    UITextPosition *documentEndPosition = [[UITextPosition alloc] init];
    
    FakeTextRange *textRangeEndingAtDocumentEnd = [[FakeTextRange alloc] init];
    textRangeEndingAtDocumentEnd.end = documentEndPosition;
    
    [[[fakeTextView stub] andReturn:textRangeEndingAtDocumentEnd] characterRangeAtPoint:CGPointZero];
    [[[fakeTextView stub] andReturn:documentEndPosition] endOfDocument];
    
    NSString *potentialLink = [textView rs_potentialLinkAtPoint:CGPointZero];
    
    assertThatInteger([potentialLink length], equalToInteger(0));
}

- (void)testEmptyPotentialLinkIfNoTextClosestToTapPoint
{
    CGPoint tapPoint = CGPointZero;
    
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] characterAtPositionIsLastCharacterInDocument:tapPoint];
    
    [[[fakeTextView stub] andReturn:nil] closestPositionToPoint:tapPoint];
    
    NSString *potentialLink = [textView rs_potentialLinkAtPoint:tapPoint];
    assertThatInteger([potentialLink length], equalToInteger(0)); // greater coupling than preferred to if it returns nil or length 0, which are both OK from the spec
}

- (UITextPosition *)newTextPosition
{
    return [[UITextPosition alloc] init];
}

- (OCMockObject *)newMock
{
    return [OCMockObject mockForClass:[NSObject class]];
}

- (void)testNoPotentialLinkIfFirstCharacterCfOrLf
{
    [[fakeTextView stub] closestPositionNotAtEndOfDocumentToPoint:CGPointZero];
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] firstCharacterIsCrOrLf:nil];
    
    assertThat([textView rs_potentialLinkAtPoint:CGPointZero], nilValue());
}

// for blog: compare:
- (void)testPotentialLinkIsGrownStringLazilyUsingNil
{
    [[fakeTextView stub] closestPositionNotAtEndOfDocumentToPoint:CGPointZero];
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){NO})] firstCharacterIsCrOrLf:nil];
    
    id grownString = [self newMock];
    [[[fakeTextView stub] andReturn:grownString] stringByGrowingStringAroundTapPosition:nil];
    
    assertThat([textView rs_potentialLinkAtPoint:CGPointZero], sameInstance(grownString));
    
}

- (void)testPotentialLinkIsGrownStringPedantic
{
    id position = [self newMock];
    
    [[[fakeTextView stub] andReturn:position] closestPositionNotAtEndOfDocumentToPoint:CGPointZero];
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){NO})] firstCharacterIsCrOrLf:position];
    
    id grownString = [self newMock];
    [[[fakeTextView stub] andReturn:grownString] stringByGrowingStringAroundTapPosition:position];
    
    assertThat([textView rs_potentialLinkAtPoint:CGPointZero], sameInstance(grownString));
}


- (void)testCrRecognized
{
    id position = [self newMock];
    
    NSString *cr = @"\n";
    [[[fakeTextView stub] andReturn:cr] characterAtPosition:position];
    
    STAssertTrue([textView firstCharacterIsCrOrLf:position], nil);
}

- (void)testLfRecognized
{
    id position = [self newMock];
    
    NSString *lf = @"\r";
    [[[fakeTextView stub] andReturn:lf] characterAtPosition:position];
    
    STAssertTrue([textView firstCharacterIsCrOrLf:position], nil);
}

- (void)testOtherCharacterOK
{
    id position = [self newMock];
    
    NSString *a = @"a";
    [[[fakeTextView stub] andReturn:a] characterAtPosition:position];
    
    STAssertFalse([textView firstCharacterIsCrOrLf:position], nil);
}

- (void)testCharacterAtPosition
{
    id position = [self newTextPosition];
    
    id range = [self newMock];
    
    id tokenizer = [OCMockObject mockForProtocol:@protocol(UITextInputTokenizer)];
    [[[fakeTextView stub] andReturn:tokenizer] tokenizer];
    
    [[[tokenizer stub] andReturn:range] rangeEnclosingPosition:position withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[fakeTextView stub] andReturn:@"a"] textInRange:range];
    
    
    assertThat([textView characterAtPosition:position], equalTo(@"a"));
}


- (void)testGrowingStringAroundTapPositionCombinesLeftAndRight
{
    id position = [self newMock];
    
    // check that each mutable stirng is the same.
    // then check that each of the below methods append to the input string
    __block CFTypeRef stringArgLeft = nil;
    __block CFTypeRef stringArgRight = nil;
    
    [[[fakeTextView stub] andDo:^(NSInvocation *invocation) {
        CFTypeRef localArg;
        [invocation getArgument:&localArg atIndex:2];
        stringArgLeft = localArg;
        CFRetain(stringArgLeft);
    }] appendToString:(id)anything() byMovingLeftFromAndNotIncludingTextPosition:position];
    
    [[[fakeTextView stub] andDo:^(NSInvocation *invocation) {
        CFTypeRef localArg;
        [invocation getArgument:&localArg atIndex:2];
        stringArgRight = localArg;
        CFRetain(stringArgRight);
    }] appendToString:(id)anything() byMovingRightFromAndIncludingTextPosition:position];
    
    
    [fakeTextView verify];
    
    NSString *string = [textView stringByGrowingStringAroundTapPosition:position];

    // check that this is the same string passed to both instances
    assertThat((__bridge id)stringArgLeft, sameInstance((__bridge id)stringArgRight));
    
    id mutableStringBuiltInto = (__bridge id)stringArgLeft; // == stringArgRight
    assertThat(string, sameInstance(mutableStringBuiltInto));
    
    CFRelease(stringArgLeft);
    CFRelease(stringArgRight);
}

- (id)newAutoverifyingMock
{
    return [self autoVerifiedMockForClass:[NSObject class]];
}



- (void)testStringByMovingRight
{
    id position1 = [self newAutoverifyingMock];
    
    NSArray *positions = @[position1, [self newAutoverifyingMock]];
    NSArray *characters = @[@"a", @"b"];
    
    [[[fakeTextView stub] andReturn:positions[1]] positionFromPosition:positions[0] offset:1];
    [[fakeTextView stub] positionFromPosition:positions[1] offset:1]; // returns nil
    
    [[[fakeTextView stub] andReturn:characters[0]] characterAtPosition:positions[0]];
    [[[fakeTextView stub] andReturn:characters[1]] characterAtPosition:positions[1]];
    
    // OCMOCK_VALUE((BOOL){YES})
    [[[fakeTextView stub] andReturn:characters[0]] characterAllowedAsPartOfLinkAtPosition:positions[0]];
    [[[fakeTextView stub] andReturn:characters[1]] characterAllowedAsPartOfLinkAtPosition:positions[1]];
    
    NSString *string = [textView stringByMovingRightFromAndIncludingTextPosition:position1];
    
    assertThat(string, equalTo(@"ab"));
}

- (void)testStringByMovingLeft
{
    id position1 = [self newAutoverifyingMock];
    
    NSArray *positions = @[position1, [self newAutoverifyingMock], [self newAutoverifyingMock]];
    NSArray *characters = @[@"a", @"b", @"c"];
    
    [[[fakeTextView stub] andReturn:positions[1]] positionFromPosition:positions[2] offset:-1];
    [[[fakeTextView stub] andReturn:positions[0]] positionFromPosition:positions[1] offset:-1];
    [[fakeTextView stub] positionFromPosition:positions[0] offset:-1]; // returns nil
    
    [[[fakeTextView stub] andReturn:characters[0]] characterAtPosition:positions[0]];
    [[[fakeTextView stub] andReturn:characters[1]] characterAtPosition:positions[1]];
    [[[fakeTextView stub] andReturn:characters[2]] characterAtPosition:positions[2]];
    
    // OCMOCK_VALUE((BOOL){YES})
    [[[fakeTextView stub] andReturn:characters[0]] characterAllowedAsPartOfLinkAtPosition:positions[0]];
    [[[fakeTextView stub] andReturn:characters[1]] characterAllowedAsPartOfLinkAtPosition:positions[1]];
    [[[fakeTextView stub] andReturn:characters[2]] characterAllowedAsPartOfLinkAtPosition:positions[2]];
    
    NSString *string = [textView stringByMovingLeftFromAndNotIncludingTextPosition:positions[2]];
    
    assertThat(string, equalTo(@"ab"));
}


- (void)testAppendToStringByMovingRight
{
    id position1 = [self newAutoverifyingMock];
    
    NSArray *positions = @[position1, [self newAutoverifyingMock]];
    NSArray *characters = @[@"a", @"b"];
    
//    NSMutableString *mutableString = [NSMutableString string];
    id mutableString = [self autoVerifiedMockForClass:[NSMutableString class]];
    
    [[[fakeTextView stub] andReturn:positions[1]] positionFromPosition:positions[0] offset:1];
    [[fakeTextView stub] positionFromPosition:positions[1] offset:1]; // returns nil
    
    [[[fakeTextView stub] andReturn:characters[0]] characterAtPosition:positions[0]];
    [[[fakeTextView stub] andReturn:characters[1]] characterAtPosition:positions[1]];
    
    // OCMOCK_VALUE((BOOL){YES})
    [[[fakeTextView stub] andReturn:characters[0]] characterAllowedAsPartOfLinkAtPosition:positions[0]];
    [[[fakeTextView stub] andReturn:characters[1]] characterAllowedAsPartOfLinkAtPosition:positions[1]];
    
    
    // expect!
    [[mutableString expect] appendString:@"a"];
    [[mutableString expect] appendString:@"b"];
    
    [textView appendToString:mutableString byMovingRightFromAndIncludingTextPosition:positions[0]];
    
//    assertThat(mutableString, equalTo(@"abc"));
}

- (void)testAppendToStringByMovingLeft
{
    id position1 = [self newAutoverifyingMock];
    
    NSArray *positions = @[position1, [self newAutoverifyingMock], [self newAutoverifyingMock]];
    NSArray *characters = @[@"a", @"b", @"c"];
    
    
    
    //    NSMutableString *mutableString = [NSMutableString string];
    id mutableString = [self autoVerifiedMockForClass:[NSMutableString class]];
    
    [[[fakeTextView stub] andReturn:positions[1]] positionFromPosition:positions[2] offset:-1];
    [[[fakeTextView stub] andReturn:positions[0]] positionFromPosition:positions[1] offset:-1];
    [[fakeTextView stub] positionFromPosition:positions[0] offset:-1]; // returns nil
    
    [[[fakeTextView stub] andReturn:characters[0]] characterAtPosition:positions[0]];
    [[[fakeTextView stub] andReturn:characters[1]] characterAtPosition:positions[1]];
    [[[fakeTextView stub] andReturn:characters[2]] characterAtPosition:positions[2]];
    
    // OCMOCK_VALUE((BOOL){YES})
    [[[fakeTextView stub] andReturn:characters[0]] characterAllowedAsPartOfLinkAtPosition:positions[0]];
    [[[fakeTextView stub] andReturn:characters[1]] characterAllowedAsPartOfLinkAtPosition:positions[1]];
    [[[fakeTextView stub] andReturn:characters[2]] characterAllowedAsPartOfLinkAtPosition:positions[2]];
    
    
    // expect!
    [[mutableString expect] insertString:@"b" atIndex:0];
    [[mutableString expect] insertString:@"a" atIndex:0];
    
    [textView appendToString:mutableString byMovingLeftFromAndNotIncludingTextPosition:positions[2]];
    
    //    assertThat(mutableString, equalTo(@"abc"));
}

@end


