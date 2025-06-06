#import "TGDataItem.h"

@interface TGDataItem () {
    NSMutableData *_data;
}

@end

@implementation TGDataItem

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _data = [[NSMutableData alloc] init];
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self != nil) {
        _data = [[NSMutableData alloc] init];
        [self appendData:data];
    }
    return self;
}

- (void)appendData:(NSData *)data {
    [_data appendData:data];
}

- (NSData *)data {
    return _data;
}

@end
