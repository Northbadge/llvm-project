; UNSUPPORTED: system-windows
;; Unsupported on Windows due to difficulty with escaping "opt" across platforms.
;; lit substitutes 'opt' with /path/to/opt.

; RUN: rm -rf %t && mkdir %t && cd %t

;; Copy IR from import-constant.ll since it generates all the temps
; RUN: opt -thinlto-bc %s -o 1.bc
; RUN: opt -thinlto-bc %p/Inputs/import-constant.ll -o 2.bc
; RUN: mkdir all build

;; Check preopt
; RUN: llvm-lto2 run 1.bc 2.bc -o build/a.out \
; RUN:    -import-constants-with-refs -r=1.bc,main,plx -r=1.bc,_Z6getObjv,l \
; RUN:    -r=2.bc,_Z6getObjv,pl -r=2.bc,val,pl -r=2.bc,outer,pl \
; RUN:    -save-temps -exit-on=preopt
; RUN: ls build/*.0.preopt*
; RUN: not ls build/*.1.promote*
; RUN: not ls build/*.2.internalize*
; RUN: not ls build/*.3.import*
; RUN: not ls build/*.4.opt*
; RUN: not ls build/*.5.precodegen*
; RUN: not ls build/a.out.1
; RUN: not ls build/a.out.2

;; Check promote
; RUN: rm -f build/*
; RUN: llvm-lto2 run 1.bc 2.bc -o build/a.out \
; RUN:    -import-constants-with-refs -r=1.bc,main,plx -r=1.bc,_Z6getObjv,l \
; RUN:    -r=2.bc,_Z6getObjv,pl -r=2.bc,val,pl -r=2.bc,outer,pl \
; RUN:    -save-temps -exit-on=promote
; RUN: ls build/*.0.preopt*
; RUN: ls build/*.1.promote*
;; 1 file is expected due to full LTO outputting .internalize bc
;; before the .promote hook (unique to ThinLTO) is hit
; RUN: ls build/*.2.internalize* | count 1
; RUN: not ls build/*.3.import*
; RUN: not ls build/*.4.opt*
; RUN: not ls build/*.5.precodegen*
; RUN: not ls build/a.out.1
; RUN: not ls build/a.out.2

;; Check internalize
; RUN: rm -f build/*
; RUN: llvm-lto2 run 1.bc 2.bc -o build/a.out \
; RUN:    -import-constants-with-refs -r=1.bc,main,plx -r=1.bc,_Z6getObjv,l \
; RUN:    -r=2.bc,_Z6getObjv,pl -r=2.bc,val,pl -r=2.bc,outer,pl \
; RUN:    -save-temps -exit-on=internalize
; RUN: ls build/*.0.preopt*
; RUN: ls build/*.1.promote*
;; 3 files are expected here and beyond due to full LTO outputting .internalize bc
;; and the ThinLTO internalize hook outputting 2 more files
; RUN: ls build/*.2.internalize* | count 3
; RUN: not ls build/*.3.import*
; RUN: not ls build/*.4.opt*
; RUN: not ls build/*.5.precodegen*
; RUN: not ls build/a.out.1
; RUN: not ls build/a.out.2

;; Check import
; RUN: rm -f build/*
; RUN: llvm-lto2 run 1.bc 2.bc -o build/a.out \
; RUN:    -import-constants-with-refs -r=1.bc,main,plx -r=1.bc,_Z6getObjv,l \
; RUN:    -r=2.bc,_Z6getObjv,pl -r=2.bc,val,pl -r=2.bc,outer,pl \
; RUN:    -save-temps -exit-on=import
; RUN: ls build/*.0.preopt*
; RUN: ls build/*.1.promote*
; RUN: ls build/*.2.internalize* | count 3
; RUN: ls build/*.3.import*
; RUN: not ls build/*.4.opt*
; RUN: not ls build/*.5.precodegen*
; RUN: not ls build/a.out.1
; RUN: not ls build/a.out.2

;; Check opt
; RUN: rm -f build/*
; RUN: llvm-lto2 run 1.bc 2.bc -o build/a.out \
; RUN:    -import-constants-with-refs -r=1.bc,main,plx -r=1.bc,_Z6getObjv,l \
; RUN:    -r=2.bc,_Z6getObjv,pl -r=2.bc,val,pl -r=2.bc,outer,pl \
; RUN:    -save-temps -exit-on=\opt
; RUN: ls build/*.0.preopt*
; RUN: ls build/*.1.promote*
; RUN: ls build/*.2.internalize* | count 3
; RUN: ls build/*.3.import*
; RUN: ls build/*.4.opt*
; RUN: not ls build/*.5.precodegen*
; RUN: not ls build/a.out.1
; RUN: not ls build/a.out.2

;; Check precodegen
; RUN: llvm-lto2 run 1.bc 2.bc -o build/a.out \
; RUN:    -import-constants-with-refs -r=1.bc,main,plx -r=1.bc,_Z6getObjv,l \
; RUN:    -r=2.bc,_Z6getObjv,pl -r=2.bc,val,pl -r=2.bc,outer,pl \
; RUN:    -save-temps -exit-on=precodegen
; RUN: ls build/*.0.preopt*
; RUN: ls build/*.1.promote*
; RUN: ls build/*.2.internalize* | count 3
; RUN: ls build/*.3.import*
; RUN: ls build/*.4.opt*
; RUN: ls build/*.5.precodegen*
; RUN: not ls build/a.out.1
; RUN: not ls build/a.out.2

;; Create the .all dir with save-temps, without exit-on, then diff
; RUN: llvm-lto2 run 1.bc 2.bc -o all/a.out \
; RUN:    -import-constants-with-refs -r=1.bc,main,plx -r=1.bc,_Z6getObjv,l \
; RUN:    -r=2.bc,_Z6getObjv,pl -r=2.bc,val,pl -r=2.bc,outer,pl \
; RUN:    -save-temps
; RUN: rm all/a.out.1 all/a.out.2
; RUN: diff -r all build

;; Check error message
; RUN: not llvm-lto2 run 1.bc 2.bc -o all/a.out \
; RUN:    -import-constants-with-refs -r=1.bc,main,plx -r=1.bc,_Z6getObjv,l \
; RUN:    -r=2.bc,_Z6getObjv,pl -r=2.bc,val,pl -r=2.bc,outer,pl \
; RUN:    -exit-on=prelink 2>&1 \
; RUN: | FileCheck %s --check-prefix=ERR1
; ERR1: invalid addExitOn parameter: prelink

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.S = type { i32, i32, i32* }

define dso_local i32 @main() local_unnamed_addr {
entry:
  %call = tail call %struct.S* @_Z6getObjv()
  %d = getelementptr inbounds %struct.S, %struct.S* %call, i64 0, i32 0
  %0 = load i32, i32* %d, align 8
  %v = getelementptr inbounds %struct.S, %struct.S* %call, i64 0, i32 1
  %1 = load i32, i32* %v, align 4
  %add = add nsw i32 %1, %0
  ret i32 %add
}

declare dso_local %struct.S* @_Z6getObjv() local_unnamed_addr
