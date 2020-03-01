# taskrc.md for taskrc-kit/test

#  Use taskrc -h for help on built-in taskrc functions.
#  To provide help for definitions in this file, add #Help tags, e.g.:
#    function my_func {
     #Help: my_func is my first and only function...

### Code source blocks
When tkr loads a taskrc.md file, any code blocks marked ```sh are sourced into the
current shell.

```sh
alias hello='echo "Hello world, from $taskrc_dir/taskrc.md"'
```



