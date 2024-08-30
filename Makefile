init:
	bundle -v || gem install bundler -V
	bundle install

preview: clean serve

clean:
	echo clean cache...
	bundle exec jekyll clean

serve:
	echo serve pages...
	bundle exec jekyll serve

.phony: init preview clean serve