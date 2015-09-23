//
//  ACEOperationTree.h
//
// Copyright (c) 2014 Stefano Acerbetti
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


#import <Foundation/Foundation.h>

@class ACEOperationTree;

// states
typedef NS_ENUM(NSInteger, ACEOperationTreeState) {
    ACEOperationTreeInit = 0,
    ACEOperationTreeStarted,
    ACEOperationTreeDone,
};

// protocols
@protocol ACEOperationTreeDelegate <NSObject>

- (void)didStartOperation:(ACEOperationTree *)operation;
- (void)didCompleteOperation:(ACEOperationTree *)operation withError:(NSError *)error;

@end


@interface ACEOperationTree : NSObject

/**
 The NSOperationQueue associated with this node
 */
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

/**
 The current state of this node
 */
@property (nonatomic, readonly) ACEOperationTreeState state;

/**
 Max number of allowed retries if failure
 */
@property (nonatomic, assign) NSUInteger maxRetryNum;

/**
 Operation delegate for the current node
 */
@property (nonatomic, weak) id<ACEOperationTreeDelegate> delegate;




- (instancetype)initWithOperationQueue:(NSOperationQueue *)operationQueue NS_DESIGNATED_INITIALIZER;


- (void)addChild:(ACEOperationTree *)child
       objectMap:(NSArray *(^)(id object))mapBlock;



@end
