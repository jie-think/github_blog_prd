install:
	hexo g

deploy: install
	hexo d

start: install
	hexo s
