
# Cheat notes: Test Commands

This is a list of test commands to use for shell scripts

Full reference: https://www.computerhope.com/unix/bash/test.htm

## single files

* `[ -d directory ]` file is a directory
* `[ -e filename ]` file exists
* `[ -f filename ]` file exists and is a regular file
* `[ -h filename ]` file exists and is a symbolic link (`-L` also does this)
* `[ -r filename ]` file is readable
* `[ -w filename ]` file is writable
* `[ -x filename ]` file is executable

## comparing files

* `[ file1 -nt file2 ]` file1 is newer than file2 
* `[ file1 -ot file2 ]` file1 is older than file2 
* `[ file1 -ef file2 ]` file1 is a hard link to file2 

## strings

* `[ -n "${string}" ]` string is not empty (the `-n` is optional)
* `[ -z "${string}" ]` string is empty
* `[ ${string1} \< ${string2} ]` string1 sorts before string2
* `[ ${string1} \> ${string2} ]` string1 sorts after string2

## numbers

* `[ ${arg1} -ne ${arg2} ]` arg1 is not equal to arg2
* `[ ${arg1} -eq ${arg2} ]` arg1 is equal to arg2
* `[ ${arg1} -lt ${arg2} ]` arg1 is numerically less than arg2
* `[ ${arg1} -le ${arg2} ]` arg1 is numerically less than or equal to arg2
* `[ ${arg1} -gt ${arg2} ]` arg1 is numerically greater than arg2
* `[ ${arg1} -ge ${arg2} ]` arg1 is numerically greater than or equal to arg2
