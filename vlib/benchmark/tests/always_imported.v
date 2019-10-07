module main

///////////////////////////////////////////////////////////////////////
/// This file will get compiled as a part of the same module,
/// in which a given _test.v file is, when v is given -stats argument
/// The methods defined here are called back by the test program's
/// main function, generated by compiler/main.v so that customizing the
/// look & feel of the results is easy, since it is done in normal V
/// code, instead of in embedded C ...
///////////////////////////////////////////////////////////////////////

import os
import benchmark
import term

struct BenchedTests {
mut:
	oks int
	fails int
	test_suit_file string
	step_func_name string
	bench benchmark.Benchmark
}

/////////////////////////////////////////////////////////////////////

// Called at the start of the test program produced by `v -stats file_test.v`
fn start_testing() BenchedTests {	
	mut b := BenchedTests{ bench: benchmark.new_benchmark() }
	b.test_suit_file = os.executable() + '.v'
	println('running tests in: $b.test_suit_file')
	return b
}

// Called before each test_ function, defined in file_test.v
fn (b mut BenchedTests) testing_step_start(stepfunc string) {
	b.step_func_name = stepfunc.replace('main__','')
	b.oks   = C.g_test_oks
	b.fails = C.g_test_fails
	b.bench.step()
}

// Called after each test_ function, defined in file_test.v
fn (b mut BenchedTests) testing_step_end() {
	ok_diff   := C.g_test_oks - b.oks
	fail_diff := C.g_test_fails - b.fails
	//////////////////////////////////////////////////////////////////
	if ok_diff == 0 && fail_diff == 0 {
		b.bench.neither_fail_nor_ok()
		println('     ' + b.bench.step_message('NO asserts | ') + b.fn_name() )
		return
	}	
	//////////////////////////////////////////////////////////////////
	if ok_diff   > 0 {
		b.bench.ok_many(ok_diff)
	}
	if fail_diff > 0 {
		b.bench.fail_many(fail_diff)
	}
	//////////////////////////////////////////////////////////////////	
	if ok_diff   > 0 && fail_diff == 0 {
		println(ok_text('OK') + b.bench.step_message(nasserts(ok_diff)) + b.fn_name() )
		return
	}
	if fail_diff > 0 {	
		println(fail_text('FAIL') + b.bench.step_message(nasserts(fail_diff)) + b.fn_name()  )
		return
	}
}

fn (b &BenchedTests) fn_name() string {
	return b.step_func_name + '()'
}

// Called at the end of the test program produced by `v -stats file_test.v`
fn (b mut BenchedTests) end_testing() {
	b.bench.stop()
	println( '     ' + b.bench.total_message('running V tests in "' + os.filename(b.test_suit_file) + '"' ) )
}

/////////////////////////////////////////////////////////////////////

fn nasserts(n int) string {
	if n==0 { return '${n:2d} asserts | ' }
	if n==1 { return '${n:2d} assert  | ' }
	return '${n:2d} asserts | '
}

fn ok_text(s string) string {
	return term.ok_message('${s:5s}')
}

fn fail_text(s string) string {
	return term.fail_message('${s:5s}')
}

