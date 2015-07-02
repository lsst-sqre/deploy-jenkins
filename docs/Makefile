TEMPFILE := $(shell mktemp -u)

all: aws_vpc.png

%.png : %.dot
	unflatten $< -o ${TEMPFILE}
	dot -Tpng ${TEMPFILE} -o $@
	rm ${TEMPFILE}

clean:
	rm *.png
