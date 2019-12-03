.PHONY: build-all
build-all: build-5.6 build-7.0 build-7.1 build-7.2 build-7.3 build-7.4

.PHONY: build-5.6
build-5.6:
	@/bin/sh ./images/5.6/setup.sh

.PHONY: build-7.0
build-7.0:
	@/bin/sh ./images/7.0/setup.sh

.PHONY: build-7.1
build-7.1:
	@/bin/sh ./images/7.1/setup.sh

.PHONY: build-7.2
build-7.2:
	@/bin/sh ./images/7.2/setup.sh

.PHONY: build-7.3
build-7.3:
	@/bin/sh ./images/7.3/setup.sh

.PHONY: build-7.4
build-7.4:
	@/bin/sh ./images/7.4/setup.sh
