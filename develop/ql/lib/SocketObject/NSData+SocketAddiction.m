//
//  NSData+SocketAddiction.m
//  ql
//
//  Created by LazySnail on 14-6-4.
//  Copyright (c) 2014年 LuoHui. All rights reserved.
//

#import "NSData+SocketAddiction.h"

//自定义64长整形字节序转义方法
#define lhtonll(x) __DARWIN_OSSwapInt64(x)
#define lntohll(x) __DARWIN_OSSwapInt64(x)

@implementation NSData (SocketAddiction)

- (long long)rw_int64AtOffset:(size_t)offset
{
    const long long *longlongbytes = (const long long *)[self bytes];
    return lntohll(longlongbytes[offset / 8]);
}

- (int)rw_int32AtOffset:(size_t)offset
{
    const int *intBytes = (const int *)[self bytes];
    return ntohl(intBytes[offset / 4]);
}

- (short)rw_int16AtOffset:(size_t)offset
{
    const short *shortBytes = (const short *)[self bytes];
    return ntohs(shortBytes[offset / 2]);
}

- (char)rw_int8AtOffset:(size_t)offset {
    const char * charBytes = (const char *)[self bytes];
    return charBytes[offset];
}

- (NSString *)rw_stringAtOffset:(size_t)offset bytesRead:(size_t *)amount{
    const char *charBytes = (const char *)[self bytes];
    NSString  * string =  [NSString stringWithUTF8String:charBytes + offset];
    *amount = strlen(charBytes + offset) +1;
    return string;
}

@end

@implementation NSMutableData (SocketAddiction)

- (void)rw_appendInt64:(long long)value
{
    value = lhtonll(value);
    [self appendBytes:&value length:8];
}

- (void)rw_appendInt32:(int)value
{
    value = htonl(value);
    [self appendBytes:&value length:4];
}

- (void)rw_appendInt16:(short)value
{
    value = htons(value);
    [self appendBytes:&value length:2];
}

- (void)rw_appendInt8:(char)value
{
    [self appendBytes:&value length:1];
}

- (void)rw_appendString:(NSString *)string
{
    
    const char * cString = [string UTF8String];
    [self appendBytes:cString length:strlen(cString) + 1];
}

@end
