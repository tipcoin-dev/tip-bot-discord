run:
	bundle exec ruby main.rb

docker.build:
	docker build -t tipcoin-dev/tip-bot-discord:latest .