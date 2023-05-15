EMACS ?= emacs
OXSVD ?= $(realpath $(shell pwd)/../scripts/svd/ox-svd.el)
SRC = svd.org
DEPS = $(shell $(EMACS) --script print-dependencies.el $(SRC))

all: scobc-a1.svd

scobc-a1.svd: $(SRC) $(OXSVD) $(DEPS)
	$(EMACS) $< --batch --load $(OXSVD) -f org-svd-export-to-svd --kill

clean:
	$(RM) *.svd *~
