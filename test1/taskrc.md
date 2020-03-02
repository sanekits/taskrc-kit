## taskrc.md for taskrc-kit/test

*  Use taskrc -h for help on built-in taskrc functions.
*  To provide help for definitions in this file, add #Help tags, e.g.:
```
function my_func {
     #Help: my_func is my first and only function...
```

* Code source blocks
When `tkr` loads a taskrc.md file, any code blocks marked ` ```bash` are sourced into the current shell.  Any number of code blocks can be defined in the file.

```bash
# Here's some code from the bash snippet:
function hello {
     #Help  This is help for hello()
     echo "Hello world, from $taskrc_dir/taskrc.md"
}
```
```bash
alias hello2="This is a \n2nd block"
```

