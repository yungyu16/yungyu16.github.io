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

compress-img:
	@if ! command -v pngquant >/dev/null 2>&1; then \
		echo "错误: 未找到 pngquant，请先安装 (brew install pngquant)"; \
		exit 1; \
	fi
	@if ! command -v sips >/dev/null 2>&1; then \
		echo "错误: 未找到 sips，无法校验图片尺寸"; \
		exit 1; \
	fi
	@target_dir="$(DIR)"; \
	if [ -z "$$target_dir" ]; then \
		target_dir=$$(find img -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort | tail -n 1); \
		if [ -z "$$target_dir" ]; then \
			echo "错误: img 下没有可用子目录"; \
			exit 1; \
		fi; \
		echo "未指定 DIR，默认使用: $$target_dir"; \
	fi; \
	if [ ! -d "$$target_dir" ]; then \
		echo "错误: 目录 $$target_dir 不存在"; \
		exit 1; \
	fi; \
	echo "压缩目录 $$target_dir 下的 PNG（保持宽高不变）..."; \
	tmp_before=$$(mktemp); \
	tmp_after=$$(mktemp); \
	trap 'rm -f "$$tmp_before" "$$tmp_after"' EXIT INT TERM; \
	find "$$target_dir" -maxdepth 1 -type f -name '*.png' | sort | while IFS= read -r img; do \
		size=$$(wc -c < "$$img" | tr -d ' '); \
		w=$$(sips -g pixelWidth "$$img" | awk '/pixelWidth/{print $$2}'); \
		h=$$(sips -g pixelHeight "$$img" | awk '/pixelHeight/{print $$2}'); \
		printf '%s\t%s\t%s\t%s\n' "$$img" "$$size" "$$w" "$$h"; \
	done > "$$tmp_before"; \
	if [ ! -s "$$tmp_before" ]; then \
		echo "未找到 PNG 文件"; \
		exit 0; \
	fi; \
	optimized=0; \
	skipped=0; \
	failed=0; \
	while IFS=$$(printf '\t') read -r img size _; do \
		pngquant --skip-if-larger --force --ext .png --quality=60-85 --speed 1 "$$img" >/dev/null 2>&1; \
		rc=$$?; \
		if [ "$$rc" -eq 0 ]; then \
			new_size=$$(wc -c < "$$img" | tr -d ' '); \
			if [ "$$new_size" -lt "$$size" ]; then \
				optimized=$$((optimized + 1)); \
			else \
				skipped=$$((skipped + 1)); \
			fi; \
		elif [ "$$rc" -eq 98 ] || [ "$$rc" -eq 99 ]; then \
			skipped=$$((skipped + 1)); \
		else \
			failed=$$((failed + 1)); \
		fi; \
	done < "$$tmp_before"; \
	find "$$target_dir" -maxdepth 1 -type f -name '*.png' | sort | while IFS= read -r img; do \
		size=$$(wc -c < "$$img" | tr -d ' '); \
		w=$$(sips -g pixelWidth "$$img" | awk '/pixelWidth/{print $$2}'); \
		h=$$(sips -g pixelHeight "$$img" | awk '/pixelHeight/{print $$2}'); \
		printf '%s\t%s\t%s\t%s\n' "$$img" "$$size" "$$w" "$$h"; \
	done > "$$tmp_after"; \
	before_total=$$(awk -F '\t' '{s+=$$2} END{print s+0}' "$$tmp_before"); \
	after_total=$$(awk -F '\t' '{s+=$$2} END{print s+0}' "$$tmp_after"); \
	saved=$$((before_total - after_total)); \
	reduced_pct=$$(awk -v b="$$before_total" -v s="$$saved" 'BEGIN{if (b==0) print "0.0"; else printf "%.1f", (s*100/b)}'); \
	dim_changed=$$(awk -F '\t' 'NR==FNR{a[$$1]=$$3"x"$$4;next}{if(a[$$1] != $$3"x"$$4) c++} END{print c+0}' "$$tmp_before" "$$tmp_after"); \
	echo "文件数: $$(wc -l < "$$tmp_before" | tr -d ' ')"; \
	echo "优化成功: $$optimized, 跳过: $$skipped, 失败: $$failed"; \
	echo "压缩前总大小: $$before_total bytes"; \
	echo "压缩后总大小: $$after_total bytes"; \
	echo "节省: $$saved bytes ($$reduced_pct%)"; \
	echo "尺寸变化文件数: $$dim_changed"

.PHONY: init local-preview preview clean local_serve serve compress-img
