JEKYLL=/usr/local/lib/ruby/gems/2.1.0/gems/jekyll-1.5.0/bin/jekyll

all:
	$(JEKYLL)

server:
	$(JEKYLL) serve --watch

clean:
	rm -rf _site/*
