$ENV{'TEXMFOUTPUT'} = '../build';
$ENV{'openout_any'} = 'a';

# Allow enough passes to resolve all cross-references
$max_repeat = 5;

# Treat pdfTeX warnings (exit code 1) as non-fatal so latexmk
# continues to completion instead of aborting mid-build.
$pdflatex = 'pdflatex %O %S; exit 0';
