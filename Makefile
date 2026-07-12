PKGNAME = `sed -n "s/Package: *\([^ ]*\)/\1/p" DESCRIPTION`
PKGVERS = `sed -n "s/Version: *\([^ ]*\)/\1/p" DESCRIPTION`

all: check

docs:
	Rscript -e 'roxygen2::roxygenise()'

js:
	cd srcjs && bun run typecheck && bun run build

test:
	Rscript -e 'pkgload::load_all("."); testthat::test_dir("tests/testthat")'

build: docs
	R CMD build .

check: build
	R CMD check --no-manual $(PKGNAME)_$(PKGVERS).tar.gz

install: build
	R CMD INSTALL $(PKGNAME)_$(PKGVERS).tar.gz

site:
	Rscript dev/scripts/build_site.R

clean:
	rm -f $(PKGNAME)_$(PKGVERS).tar.gz
	rm -rf $(PKGNAME).Rcheck

.PHONY: all docs js test build check install site clean
