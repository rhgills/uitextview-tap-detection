#import "NSString+RSExtras.h"

@implementation UITextView (RSExtras)

static BOOL stringCharacterIsAllowedAsPartOfLink(NSString *s) {

    /*[s length] is assumed to be 0 or 1. s may be nil.
     Totally not a strict check.*/

    if (s == nil || [s length] < 1)
        return NO;

    unichar ch = [s characterAtIndex:0];
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch])
        return NO;
    return YES;
}

- (UITextPosition *)closestPositionNotAtEndOfDocumentToPoint:(CGPoint)point
{
    /*If we don't check for end of document, then you could tap way below end of text, and it would return a link if the last text was a link. This has the unfortunate side effect that you can't tap on the last character of a link if it appears at the end of a document. I can live with shipping that.*/
    
    if ([self characterAtPositionIsLastCharacterInDocument:point]) {
        return nil;
    }

    return [self closestPositionToPoint:point];
}

- (BOOL)characterAtPositionIsLastCharacterInDocument:(CGPoint)point
{
    UITextRange *textRange = [self characterRangeAtPoint:point];
    UITextPosition *endOfDocumentTextPosition = self.endOfDocument;
    if ([textRange.end isEqual:endOfDocumentTextPosition])
        return YES;
    
    return NO;
}

- (NSString *)rs_potentialLinkAtPoint:(CGPoint)point {
    UITextPosition *tapPosition = [self closestPositionNotAtEndOfDocumentToPoint:point];
    
    if ([self firstCharacterIsCrOrLf:tapPosition]) {
        return nil;
    }
    
    return [self stringByGrowingStringAroundTapPosition:tapPosition];
}

- (NSString *)stringByGrowingStringAroundTapPosition:(UITextPosition *)tapPosition
{
    NSMutableString *s = [NSMutableString stringWithString:@""];
    [self appendToString:s byMovingRightFromAndIncludingTextPosition:tapPosition];
    [self appendToString:s byMovingLeftFromAndNotIncludingTextPosition:tapPosition];
    
    return s;
}

- (BOOL)firstCharacterIsCrOrLf:(UITextPosition *)startingTextPosition
{
    NSString *oneCharacter = [self characterAtPosition:startingTextPosition];
    if ([oneCharacter isEqualToString:@"\n"] || [oneCharacter isEqualToString:@"\r"])
        return YES;

    return NO;
}

- (void)appendToString:(NSMutableString *)s byMovingRightFromAndIncludingTextPosition:(UITextPosition *)textPosition
{
    return [self appendToString:s
               byMovingByOffset:RightOffset
               fromTextPosition:textPosition];
}

- (void)appendToString:(NSMutableString *)s byMovingLeftFromAndNotIncludingTextPosition:(UITextPosition *)textPosition
{
    textPosition = [self positionFromPosition:textPosition offset:LeftOffset];
    
    [self appendToString:s
        byMovingByOffset:LeftOffset
        fromTextPosition:textPosition];
}

- (void)appendToString:(NSMutableString *)s byMovingByOffset:(NSInteger)offset fromTextPosition:(UITextPosition *)textPosition
{
    [self forAllowedCharacterStartingAtTextPosition:textPosition
                                    movingBy:offset
                                          do:^(NSString *character) {
                                              if (!character) {
                                                  return;
                                              }
                                              
                                              [self addCharacter:character
                                               intoMutableString:s
                                  atFrontOrBackDependingOnOffset:offset];
                                          }];
}

typedef void(^CharacterBlock)(NSString *character);
- (void)forAllowedCharacterStartingAtTextPosition:(UITextPosition *)startPosition movingBy:(NSInteger)offset do:(CharacterBlock)block
{
    [self forTextPositionStartingAt:startPosition
                           movingBy:offset
                                 do:^(UITextPosition *textPosition) {
                                     NSString *oneCharacter = [self characterAllowedAsPartOfLinkAtPosition:textPosition];
                                     block(oneCharacter);
                                 }];
}


typedef void(^TextPositionBlock)(UITextPosition *textPosition);
- (void)forTextPositionStartingAt:(UITextPosition *)startPosition movingBy:(NSInteger)offset do:(TextPositionBlock)block
{    
    for (UITextPosition *textPosition = startPosition;
         textPosition != nil;
         textPosition = [self positionFromPosition:textPosition offset:offset])
    {
        block(textPosition);
    }
}

- (NSString *)characterAllowedAsPartOfLinkAtPosition:(UITextPosition *)textPosition
{
    NSString *oneCharacter = [self characterAtPosition:textPosition];
    if (!stringCharacterIsAllowedAsPartOfLink(oneCharacter))
        return nil;
    
    return oneCharacter;
}

- (NSString *)characterAtPosition:(UITextPosition *)textPosition
{
    UITextRange *rangeOfCharacter = [self.tokenizer rangeEnclosingPosition:textPosition withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    NSString *oneCharacter = [self textInRange:rangeOfCharacter];
    return oneCharacter;
}

static const NSInteger LeftOffset = -1;
static const NSInteger RightOffset = 1;
- (void)addCharacter:(NSString *)oneCharacter intoMutableString:(NSMutableString *)s atFrontOrBackDependingOnOffset:(NSInteger)offset
{
    if (offset == RightOffset) {
        [s appendString:oneCharacter];
    }else if( offset == LeftOffset) {
        [s insertString:oneCharacter atIndex:0];
    }
}

- (NSString *)rs_linkAtPoint:(CGPoint)point {

    NSString *potentialLink = [self rs_potentialLinkAtPoint:point];
    if ([self potentialLinkIsEmpty:potentialLink]) {
        return nil;
    }

    return [self linkFromPotentialLink:potentialLink];
}

// private
- (BOOL)potentialLinkIsEmpty:(NSString *)potentialLink
{
    if (potentialLink == nil || [potentialLink length] < 1)
        return YES;
    
    return NO;
}

- (NSString *)linkFromPotentialLink:(NSString *)potentialLink
{
    NSArray *links = [potentialLink rs_links];
    if (arrayIsEmpty(links))
        return nil;
    
    NSString *firstLink = links[0];
    return firstLink;
}

static BOOL arrayIsEmpty(NSArray *array)
{
    if (array == nil || [array count] < 1)
        return YES;
    
    return NO;
}


@end