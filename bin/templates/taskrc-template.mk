# taskrc.mk for <TaskrcDir>
#
#  TODO: add targets for your project here.  When you run
#  "tmk <target-name>", the current dir will not change but
#  this makefile will be invoked.


# See https://stackoverflow.com/a/73509979/237059
absdir:=$(taskrc_dir)

REMAKE := $(MAKE) -f $(lastword $(MAKEFILE_LIST))

.PHONY: help
help:
	@echo "Targets in $(basename $(lastword $(MAKEFILE_LIST))):" >&2
	@$(REMAKE) -s --print-data-base --question no-such-target 2>/dev/null | \
	grep -Ev  -e '^taskrc.mk' -e '^help' -e '^(Makefile|GNUmakefile|makefile|no-such-target)' | \
	awk '/^[^.%][-A-Za-z0-9_]*:/ \
			{ print substr($$1, 1, length($$1)-1) }' | \
	sort | \
	pr --omit-pagination --width=100 --columns=3

.PHONY: my-target-1
my-target-1:
	@echo "Hello my-target-1, PWD=$$PWD, taskrc_dir=$$taskrc_dir"
