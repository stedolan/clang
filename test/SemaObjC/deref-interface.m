// RUN: %clang_cc1 -fobjc-nonfragile-abi -verify -fsyntax-only %s

@interface NSView 
  - (id)initWithView:(id)realView;
@end

@implementation NSView
 - (id)initWithView:(id)realView {
     *(NSView *)self = *(NSView *)realView;	// expected-error {{cannot assign to class object in non-fragile ABI}}
 }
@end

