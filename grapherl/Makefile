#CLIENT_PATH := $(wildcard _build/default/rel/grapherl/lib/graph_web-*)
CLIENT_PATH := _build/default/rel/grapherl/lib/graph_web-0.2.1


all: compile release

compile:
	./rebar3 compile

release:
	./rebar3 release
	rm -rf $(CLIENT_PATH)/priv
	mkdir -p $(CLIENT_PATH)/priv
	cp -R apps/graph_web_client/build/* $(CLIENT_PATH)/priv

client:
	cd apps/graph_web_client && grunt
	rm -rf $(CLIENT_PATH)/priv
	mkdir -p $(CLIENT_PATH)/priv
	cp -R apps/graph_web_client/build/* $(CLIENT_PATH)/priv


console:
	_build/default/rel/grapherl/bin/grapherl console
