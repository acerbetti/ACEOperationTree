//
//  ACEOperationTree.m
//
// Copyright (c) 2015 Stefano Acerbetti
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "ACEOperationTree.h"

@interface ACEOperationTree()
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) ACEOperationTreeState state;

@property (nonatomic, strong) NSMutableSet *children;
@property (nonatomic, strong) NSCountedSet *retries;
@end


@implementation ACEOperationTree

- (instancetype)initWithOperationQueue:(NSOperationQueue *)operationQueue
{
    self = [super init];
    if (self != nil) {
        self.operationQueue = operationQueue;
        self.children = [NSMutableSet new];
        self.retries = [NSCountedSet new];
        self.state = ACEOperationTreeInit;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithOperationQueue:nil];
}

- (NSOperationQueue *)operationQueue
{
    if (_operationQueue == nil) {
        _operationQueue = [NSOperationQueue new];
    }
    return _operationQueue;
}


#pragma mark - Add

- (void)addChild:(ACEOperationTree *)child
       objectMap:(NSArray *(^)(id object))mapBlock
{
    [self.children addObject:child];
}


#pragma mark - Override

- (void)operationMapForObject:(id)object completion:(void(^)(NSArray *objects))completion
{
    if (completion) {
        completion(nil);
    }
}

- (NSOperation *)operationForObject:(id)object
                       continuation:(void(^)(id object, void(^completion)()))continuation
                            failure:(void(^)(NSError *error))failure
{
    return nil;
}



#pragma mark - Run

- (void)runOperationWithObject:(id)object
                    completion:(void(^)())completion
{
    dispatch_group_t group = dispatch_group_create();
    for (ACEOperationTree *child in _children) {
        dispatch_group_enter(group);
        [child enqueueOperationsForObject:object completion:^{
            dispatch_group_leave(group);
        }];
    }
    
    // the completion block will be called after all child nodes have called their completion block
    dispatch_group_notify(group, dispatch_get_main_queue(), completion);
}

- (void)enqueueOperationsForObject:(id)object completion:(void(^)(void))completion
{
    [self operationMapForObject:object
                     completion:^(NSArray *objects) {
                         
        dispatch_group_t group = dispatch_group_create();
        
        for (id object in objects) {
            [self enqueueOperationForObject:object dispatchGroup:group];
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), completion);
    }];
}

- (void)enqueueOperationForObject:(id)object dispatchGroup:(dispatch_group_t)group
{
    dispatch_group_enter(group);
    
    __weak __typeof(self)weakSelf = self;
    
    NSOperation *operation = [self operationForObject:object
                                         continuation:^(id result, void(^completion)(void)) {
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 
                                                 [weakSelf runOperationWithObject:result
                                                                   completion:^{
                                                     
                                                     // call the completion block associated with this node
                                                     if (completion != nil)
                                                         completion();
                                                     
                                                     dispatch_group_leave(group);
                                                 }];
                                             });
                                             
                                         } failure:^(NSError *error) {
                                                  [weakSelf.retries addObject:object];
                                                  
                                                  // retry failed operations
                                                  if ([weakSelf.retries countForObject:object] < weakSelf.maxRetryNum) {
                                                      [weakSelf enqueueOperationForObject:object
                                                                            dispatchGroup:group];
                                                  } else {
                                                      // TODO: failed
                                                  }
                                                  
                                                  dispatch_group_leave(group);
                                              }];
    
    [self.operationQueue addOperation:operation];
}

@end
