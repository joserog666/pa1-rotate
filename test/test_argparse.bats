#!/usr/bin/env bats

setup() {
    touch foo_test.txt
    echo "content" > foo_test.txt
}

teardown() {
    rm -f foo_test.txt foo_test.txt.[1-9] foo_test.txt.[1-9].gz
}

@test "show help with -h and exit successfully" {
    run ../rotate -h
    [ "$status" -eq 0 ]
}

@test "show help with -h without filename" {
    run ../rotate -h
    [ "$status" -eq 0 ]
}

@test "show help with -h ignores filename if provided" {
    run ../rotate -h foo_test.txt
    [ "$status" -eq 0 ]
}

@test "backup flag alone with filename" {
    run ../rotate -b 5 foo_test.txt
    [ "$status" -eq 0 ]
}

@test "delete flag alone with filename" {
    run ../rotate -d foo_test.txt
    [ "$status" -eq 0 ]
}

@test "list flag alone with filename" {
    run ../rotate -l foo_test.txt
    [ "$status" -eq 0 ]
}

@test "compress flag alone with filename works as backup with compression" {
    run ../rotate -z foo_test.txt
    [ "$status" -eq 0 ]
    [ -f foo_test.txt.1.gz ]
}

@test "backup and compress flags together with filename" {
    run ../rotate -b 5 -z foo_test.txt
    [ "$status" -eq 0 ]
}

@test "compress and backup flags together with filename (reversed order)" {
    run ../rotate -z -b 5 foo_test.txt
    [ "$status" -eq 0 ]
}

@test "backup and delete flags together should fail" {
    run ../rotate -b 5 -d foo_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Wrong Argument Combination" ]]
}

@test "backup and list flags together should fail" {
    run ../rotate -b 5 -l foo_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Wrong Argument Combination" ]]
}

@test "delete and list flags together should fail" {
    run ../rotate -d -l foo_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Wrong Argument Combination" ]]
}

@test "delete and compress flags together should fail" {
    run ../rotate -d -z foo_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Wrong Argument Combination" ]]
}

@test "list and compress flags together should fail" {
    run ../rotate -l -z foo_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Wrong Argument Combination" ]]
}

@test "three flags together should fail" {
    run ../rotate -b 5 -d -l foo_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Too many Arguments" ]]
}

@test "all four flags together should fail" {
    run ../rotate -b 5 -d -l -z foo_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Too many Arguments" ]]
}

@test "backup flag without number should fail" {
    run ../rotate -b foo_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a number between 1 and 9" ]]
}

@test "backup flag without filename should fail" {
    run ../rotate -b 5
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No filename provided" ]]
}

@test "delete flag without filename should fail" {
    run ../rotate -d
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No filename provided" ]]
}

@test "list flag without filename should fail" {
    run ../rotate -l
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No filename provided" ]]
}

@test "compress flag without filename should fail" {
    run ../rotate -z
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No filename provided" ]]
}

@test "no flags and no filename should fail" {
    run ../rotate
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No filename provided" ]]
}

@test "backup with non-existent file should fail" {
    run ../rotate -b 5 non_existent.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "File does not exist" ]]
}

@test "delete with non-existent file should fail" {
    run ../rotate -d non_existent.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "File does not exist" ]]
}

@test "list with non-existent file should fail" {
    run ../rotate -l non_existent.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "File does not exist" ]]
}

@test "two filenames should fail" {
    run ../rotate -b 5 foo_test.txt bar_test.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Too many arguments" ]]
}

@test "empty file produces no backup and exits successfully" {
    rm foo_test.txt
    touch foo_test.txt
    run ../rotate foo_test.txt
    [ "$status" -eq 0 ]
    [ ! -f foo_test.txt.1 ]
}

@test "empty file with -z produces no backup and exits successfully" {
    rm foo_test.txt
    touch foo_test.txt
    run ../rotate -z foo_test.txt
    [ "$status" -eq 0 ]
    [ ! -f foo_test.txt.1.gz ]
}

@test "empty file with explicit -b produces no backup" {
    rm foo_test.txt
    touch foo_test.txt
    run ../rotate -b 3 foo_test.txt
    [ "$status" -eq 0 ]
    [ ! -f foo_test.txt.1 ]
}