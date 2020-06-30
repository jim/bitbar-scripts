.DEFAULT_GOAL := build

build/calendar_data: src/calendar_data.cr
	crystal build src/calendar_data.cr -o build/calendar_data

build/calendar_menu: src/calendar_menu.cr
	crystal build src/calendar_menu.cr -o build/calendar_menu

build/jira_data: src/jira_data.cr
	crystal build src/jira_data.cr -o build/jira_data

build/jira_menu: src/jira_menu.cr
	crystal build src/jira_menu.cr -o build/jira_menu

build/clocks: src/clocks.cr
	crystal build src/clocks.cr -o build/clocks

build: build/calendar_data build/calendar_menu build/jira_data build/jira_menu build/clocks
.PHONY: build

clean:
	rm build/*
.PHONY: clean