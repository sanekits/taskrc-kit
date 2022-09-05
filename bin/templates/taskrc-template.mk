# taskrc.mk for <TaskrcDir>
#
#  TODO: add targets for your project here.  When you run
#  "tmk <target-name>", the current dir will not change but
#  this makefile will be invoked.

.PHONY: help
help:
	@$(MAKE) -s --print-data-base --question no-such-target 2>/dev/null | \
	grep -v  -e '^taskrc.mk' -e '^help' | \
	awk '/^[^.%][-A-Za-z0-9_]*:/ \
			{ print substr($$1, 1, length($$1)-1) }' | \
	sort | \
	pr --omit-pagination --width=100 --columns=3

# See https://stackoverflow.com/a/73509979/237059
absdir:=$(taskrc_dir)


.PHONY: my-target-1
my-target-1:
	@echo "Hello my-target-1, PWD=$$PWD, taskrc_dir=$$taskrc_dir"
