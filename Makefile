init:
	bundle -v || gem install bundler -V
	bundle install

local-preview: clean local_serve

preview: clean serve

clean:
	echo clean cache...
	bundle exec jekyll clean

local_serve:
	echo serve pages...
	JEKYLL_ENV=development bundle exec jekyll serve

serve:
	echo serve pages...
	JEKYLL_ENV=production bundle exec jekyll serve

.phony: init preview clean serve