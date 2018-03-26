TEMPFILE := $(shell mktemp -u)

all: aws_vpc.png aws_squash.png

%.png : %.dot
	unflatten $< -l2 -o ${TEMPFILE}
	dot -Tpng ${TEMPFILE} -o $@
	rm ${TEMPFILE}

clean:
	rm *.png
