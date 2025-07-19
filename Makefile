init:
	bundle -v || gem install bundler -V
	bundle install

preview: clean css serve

clean:
	echo clean cache...
	bundle exec jekyll clean

css:
	echo build css...
	npm start

serve:
	echo serve pages...
	bundle exec jekyll serve

.phony: init preview clean serve