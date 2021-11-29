##
# run make to compile and link to ~/bin

compile:
	@sh ./make/compile

pre:
	@sh ./make/pre

all: pre compile

clean:
	@sh ./make/clean
# EOF
##