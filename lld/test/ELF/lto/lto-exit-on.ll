;; This test is similar to llvm/test/ThinLTO/X86/exit-on.ll

; REQUIRES: x86
; UNSUPPORTED: system-windows
;; Unsupported on Windows due to difficulty with escaping "opt" across platforms.
;; lit substitutes 'opt' with /path/to/opt.

; RUN: rm -fr %t && mkdir %t && cd %t
; RUN: mkdir all all2 build
; RUN: cd build

; RUN: opt -thinlto-bc -o main.o %s
; RUN: opt -thinlto-bc -o thin1.o %S/Inputs/thinlto.ll

;; Check preopt
; RUN: rm -f *.o.*
; RUN: ld.lld main.o thin1.o --save-temps --lto-exit-on=preopt
; RUN: ls *.0.preopt*
; RUN: not ls *.1.promote*
; RUN: not ls *.2.internalize*
; RUN: not ls *.3.import*
; RUN: not ls *.4.opt*
; RUN: not ls *.5.precodegen*
; RUN: ls a.out*.lto.o
; RUN: not ls a.out

;; Check promote
; RUN: rm -f *.o.*
; RUN: ld.lld main.o thin1.o --save-temps --lto-exit-on=promote
; RUN: ls *.0.preopt*
; RUN: ls *.1.promote*
;; 1 file is expected due to full LTO outputting .internalize bc
;; before the .promote hook (unique to ThinLTO) is hit
; RUN: ls *.2.internalize* | count 1
; RUN: not ls *.3.import*
; RUN: not ls *.4.opt*
; RUN: not ls *.5.precodegen*
; RUN: ls a.out*.lto.o
; RUN: not ls a.out

;; Check internalize
; RUN: rm -f *.o.*
; RUN: ld.lld main.o thin1.o --save-temps --lto-exit-on=internalize
; RUN: ls *.0.preopt*
; RUN: ls *.1.promote*
;; 3 files are expected here and beyond due to full LTO outputting .internalize bc
;; and the ThinLTO internalize hook outputting 2 more files
; RUN: ls *.2.internalize* | count 3
; RUN: not ls *.3.import*
; RUN: not ls *.4.opt*
; RUN: not ls *.5.precodegen*
; RUN: ls a.out*.lto.o
; RUN: not ls a.out

;; Check import
; RUN: rm -f *.o.*
; RUN: ld.lld main.o thin1.o --save-temps --lto-exit-on=import
; RUN: ls *.0.preopt*
; RUN: ls *.1.promote*
; RUN: ls *.2.internalize* | count 3
; RUN: ls *.3.import*
; RUN: not ls *.4.opt*
; RUN: not ls *.5.precodegen*
; RUN: ls a.out*.lto.o
; RUN: not ls a.out

;; Check opt
; RUN: rm -f *.o.*
; RUN: ld.lld main.o thin1.o --save-temps --lto-exit-on=\opt
; RUN: ls *.0.preopt*
; RUN: ls *.1.promote*
; RUN: ls *.2.internalize* | count 3
; RUN: ls *.3.import*
; RUN: ls *.4.opt*
; RUN: not ls *.5.precodegen*
; RUN: ls a.out*.lto.o
; RUN: not ls a.out

;; Check precodegen
; RUN: rm -f *.o.*
; RUN: ld.lld main.o thin1.o --save-temps --lto-exit-on=precodegen
; RUN: ls *.0.preopt*
; RUN: ls *.1.promote*
; RUN: ls *.2.internalize* | count 3
; RUN: ls *.3.import*
; RUN: ls *.4.opt*
; RUN: ls *.5.precodegen*
; RUN: ls a.out*.lto.o
; RUN: not ls a.out

;; Check prelink
; RUN: rm -f *.o.* a.out*
; RUN: ld.lld main.o thin1.o --save-temps --lto-exit-on=prelink
; RUN: ls *.0.preopt*
; RUN: ls *.1.promote*
; RUN: ls *.2.internalize* | count 3
; RUN: ls *.3.import*
; RUN: ls *.4.opt*
; RUN: ls *.5.precodegen*
; RUN: ls a.out*.lto.o
; RUN: not ls a.out

;; Check output files are as expected
; RUN: mv *.o.* a.out* %t/all2

;; Create the .all dir with save-temps, without exit-on, then diff
; RUN: ld.lld main.o thin1.o --save-temps
; RUN: rm a.out
; RUN: mv *.o.* a.out* %t/all
; RUN: diff -r %t/all %t/all2

;; Check input validation
; RUN: not ld.lld main.o thin1.o --save-temps --lto-exit-on=notastage 2>&1 \
; RUN: | FileCheck %s --check-prefix=ERR1
; ERR1: unknown --lto-exit-on value: notastage

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @g()

define i32 @_start() {
  call void @g()
  ret i32 0
}
