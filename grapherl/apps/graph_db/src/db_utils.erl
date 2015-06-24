-module(db_utils).

-export([unix_time/0
        ,db_live/1
        ,get_avg_interval/1
        ,db_minutes/1
        ,db_hours/1
        ,db_days/1
        ,get_metric_name/2
        ,get_next_type/1
        ,get_interval/1
        ,get_aggregation_size/1
        ]).

%% calendar:datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}}).
-define(UNIX_EPOCH, 62167219200).


unix_time() ->
    datetime_to_unix_time(erlang:universaltime()).

datetime_to_unix_time({{_,_,_},{_,_,_}} = DateTime) ->
    calendar:datetime_to_gregorian_seconds(DateTime) - ?UNIX_EPOCH.

db_live(Name) when is_binary(Name) ->
    Name.

db_minutes(Name) when is_binary(Name) ->
    <<Name/binary, "_minutes">>.

db_hours(Name) when is_binary(Name) ->
    <<Name/binary, "_hours">>.

db_days(Name) when is_binary(Name) ->
    <<Name/binary, "_days">>.

%% for a list for {Key, Val} get the average difference between keys
get_avg_interval([]) ->
    error;
get_avg_interval([{_K, _V}]) ->
    error;
get_avg_interval(List) ->
    get_avg_interval(List, 0, 0).

get_avg_interval([], Count, Acc) ->
    Acc/Count;
get_avg_interval([{_K1, _}], Count, Acc) ->
    Acc/Count;
get_avg_interval([{K1, _}, {K2, _} | Rest], Count, Acc) ->
    AccNew = erlang:abs(binary_to_integer(K2) - binary_to_integer(K1)) + Acc,
    get_avg_interval(Rest, Count + 1, AccNew).


%% gives the name of next metric based on current type.
get_metric_name(sec, Name) ->
    db_live(Name);
get_metric_name(min, Name) ->
    db_minutes(Name);
get_metric_name(hour, Name) ->
    db_hours(Name);
get_metric_name(days, Name) ->
    db_days(Name);
get_metric_name(_, Name) ->
    db_days(Name).


get_next_type(init) -> min;
get_next_type(sec)  -> min;
get_next_type(min)  -> hour;
get_next_type(hour) -> day;
get_next_type(day)  -> stop;
get_next_type(_)    -> stop.

get_interval(sec)  -> 60;
get_interval(min)  -> 3600;
get_interval(hour) -> 86400;
get_interval(day)  -> 86400;
get_interval(_)    -> 86400.

get_aggregation_size(sec)  -> 3600 * 24;
get_aggregation_size(min)  -> 3600 * 24 * 7;
get_aggregation_size(hour) -> 3600 * 24 * 365;
%% keep the diff for day to be large so that no compression occurs
get_aggregation_size(day)  -> 3600 * 24 * 365 * 100;
get_aggregation_size(_)  -> 3600 * 24 * 365 * 100.
