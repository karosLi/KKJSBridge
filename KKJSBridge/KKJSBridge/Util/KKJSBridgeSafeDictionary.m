//
//  KKJSBridgeSafeDictionary.m
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//  Copyright © 2020 karosli. All rights reserved.
//

#import "KKJSBridgeSafeDictionary.h"

@interface KKJSBridgeSafeDictionary()

@property (nonatomic, strong) NSMutableDictionary *storage;
@property (nonatomic, strong) dispatch_queue_t readWriteQuene;

@end

@implementation KKJSBridgeSafeDictionary

- (instancetype)initCommon {
    self = [super init];
    if (self) {
        _readWriteQuene = dispatch_queue_create([@"KKJSBridgeSafeDictionary readWriteQuene Queue" UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (instancetype)init {
    self = [self initCommon];
    if (self) {
        _storage = [NSMutableDictionary dictionary];
    }
    return self;
}
 
- (instancetype)initWithCapacity:(NSUInteger)numItems {
    self = [self initCommon];
    if (self) {
        _storage = [NSMutableDictionary dictionaryWithCapacity:numItems];
    }
    return self;
}
 
- (instancetype)initWithContentsOfFile:(NSString *)path {
    self = [self initCommon];
    if (self) {
        _storage = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    }
    return self;
}
 
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self initCommon];
    if (self) {
        _storage = [[NSMutableDictionary alloc] initWithCoder:aDecoder];
    }
    return self;
}
 
- (instancetype)initWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt {
    self = [self initCommon];
    if (self) {
        _storage = [NSMutableDictionary dictionary];
        for (NSUInteger i = 0; i < cnt; ++i) {
            _storage[keys[i]] = objects[i];
        }
    }
    return self;
}
 
- (NSUInteger)count {
    __block NSUInteger count;
    dispatch_sync(_readWriteQuene, ^{
        count = self.storage.count;
    });
    return count;
}
 
- (id)objectForKey:(id)aKey {
    __block id obj;
    dispatch_sync(_readWriteQuene, ^{
        obj = self.storage[aKey];
    });
    return obj;
}
 
- (NSEnumerator *)keyEnumerator {
    __block NSEnumerator *enu;
    dispatch_sync(_readWriteQuene, ^{
        enu = [self.storage keyEnumerator];
    });
    return enu;
}
 
- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    dispatch_barrier_async(_readWriteQuene, ^{
        self.storage[aKey] = anObject;
    });
}
 
- (void)removeObjectForKey:(id)aKey {
    dispatch_barrier_async(_readWriteQuene, ^{
        [self.storage removeObjectForKey:aKey];
    });
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    dispatch_barrier_async(_readWriteQuene, ^{
        self.storage[key] = obj;
    });
}

- (id)objectForKeyedSubscript:(id)key {
    __block id obj;
    dispatch_sync(_readWriteQuene, ^{
        obj = _storage[key];
    });
    return obj;
}

@end
