##
# run make to compile and link to ~/bin

compile:
	@bash ./make/compile

pre:
	@bash ./make/pre

all: pre compile

clean:
	@bash ./make/clean
# EOF
##