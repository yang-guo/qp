SHELL := /bin/bash
BINBASE := $(dir $(shell command -v q))

.PHONY : install install_qp install_qpm install_qpr uninstall uninstall_qp uninstall_qpm uninstall_qpr

install : install_qpm install_qp

install_qp : 
	@if ! hash q 2>/dev/null; then echo "q not installed"; exit 1; fi; \
	if [ -z "$$QHOME" ]; then QHOME=$$HOME/q; fi; \
	if [ -z "$$QINIT" ]; then QINIT=$$QHOME/q.q; fi; \
	if [ -f $$QINIT ]; then \
		if grep -Rq "\.q\.import.*" $$QINIT; then sed -i '' '/\.q\.import.*/d' $$QINIT; fi; \
		cat qp.q | tr -d "\n" >> $$QINIT; \
	else \
		cat qp.q | tr -d "\n" > $$QINIT; \
	fi

install_qpm : 
	@if ! hash q 2>/dev/null; then echo "q not installed"; exit 1; fi; \
	if [ -z "$$QHOME" ]; then QHOME=$$HOME/q; fi; \
	cp qpm.q $$QHOME; \
	printf '%s\n' '#!/bin/bash' "exec q qpm.q \$$@ -q" > $(BINBASE)/qpm; \
	chmod u+x $(BINBASE)/qpm;

install_qpr : 
	@if ! hash q 2>/dev/null; then echo "q not installed"; exit 1; fi; \
	if [ -z "$$QHOME" ]; then QHOME=$$HOME/q; fi; \
	cp qpr.q $$QHOME; \
	printf '%s\n' '#!/bin/bash' "exec q qpr.q \$$@ -q" > $(BINBASE)/qpr; \
	chmod u+x $(BINBASE)/qpr;

uninstall : uninstall_qpm uninstall_qp

uninstall_qp :
	@if ! hash q 2>/dev/null; then echo "q not installed"; exit 1; fi; \
	if [ -z "$$QHOME" ]; then QHOME=$$HOME/q; fi; \
	if [ -z "$$QINIT" ]; then QINIT=$$QHOME/q.q; fi; \
	if [ -f $$QINIT ]; then sed -i '' "/\.q\.import.*/d" $$QINIT; fi;

uninstall_qpm :
	@if ! hash q 2>/dev/null; then echo "q not installed"; exit 1; fi; \
	if [ -z "$$QHOME" ]; then QHOME=$$HOME/q; fi; \
	rm -f $$QHOME/qpm.q; \
	rm -f $(BINBASE)/qpm;

uninstall_qpr :
	@if ! hash q 2>/dev/null; then echo "q not installed"; exit 1; fi; \
	if [ -z "$$QHOME" ]; then QHOME=$$HOME/q; fi; \
	rm -f $$QHOME/qpr.q; \
	rm -f $(BINBASE)/qpr;

