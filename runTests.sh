# !/bin/sh -e

ls tests/unit/*Test.R | xargs -I testFile R --slave -f testFile
