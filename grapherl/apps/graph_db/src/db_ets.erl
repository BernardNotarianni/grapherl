-module(db_ets).
-behaviour(gen_db).

-export([init_db/2,
         delete_db/1,
         read_all/1,
         insert/2,
         insert_many/2,
         delete_all/1]).

-include_lib("graph_db_records.hrl").

%% ----------------------------------------------------------------------------
%% Database API
%% ----------------------------------------------------------------------------
%% NOTE: the State var is only sotre attributes related to db like url etc. its
%% not update at all.

%% init db: return {ok, Params}
init_db(MetricName, Args) when is_binary(MetricName) ->
    init_db(binary_to_atom(MetricName, utf8), Args);

init_db(MetricName, _Args) when is_atom(MetricName) ->
    ets:new(MetricName, [set, public, named_table,
                         {write_concurrency, true},
                         {read_concurrency, false}]),
    {ok, #{}}.



%% remove Database
delete_db(MetricName) when is_binary(MetricName) ->
    delete_db(binary_to_atom(MetricName, utf8));

delete_db(MetricName) when is_atom(MetricName) ->
    true = ets:delete(MetricName),
    {ok, success}.



%% read all data points from db
read_all(MetricName) when is_binary(MetricName) ->
    read_all(binary_to_atom(MetricName, utf8));

read_all(MetricName) when is_atom(MetricName) ->
    MetricPoints     = ets:match(MetricName, '$1'),
    {ok, DataPoints} = unwrap_points(MetricPoints, []),
    {ok, DataPoints}.



%% insert data point into db
insert(MetricName, DataPoint) when is_binary(MetricName) ->
    insert(binary_to_atom(MetricName, utf8), DataPoint);

insert(MetricName, DataPoint) when is_atom(MetricName) ->
    true = ets:insert(MetricName, DataPoint),
    {ok, success}.



%% insert multiple data points
insert_many(MetricName, DataPoints) when is_binary(MetricName) ->
    insert_many(binary_to_atom(MetricName, utf8), DataPoints);

insert_many(_MetricName, []) ->
    {ok, success};
insert_many(MetricName, [DataPoint | Rest]) ->
    insert(MetricName, DataPoint),
    insert_many(MetricName, Rest).



%% delete all data points
delete_all(MetricName) when is_binary(MetricName) ->
    delete_all(binary_to_atom(MetricName, utf8));

delete_all(MetricName) when is_atom(MetricName) ->
    true = ets:delete_all_objects(MetricName),
    {ok, success}.


%% ----------------------------------------------------------------------------
%% Internal Functions
%% ----------------------------------------------------------------------------

unwrap_points([], Acc) ->
    {ok, lists:reverse(Acc)};
unwrap_points([[DataPoint] | Rest], Acc) ->
    unwrap_points(Rest, [DataPoint | Acc]).
